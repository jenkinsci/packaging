#!/bin/bash
set -euxo pipefail

: "${AGENT_WORKDIR:=/tmp}"
: "${GPG_KEYNAME:?Require valid gpg keyname}"
: "${RPMDIR:?Require where to put binary files}"
: "${RPM_WEBDIR:?Require where to put index and other web contents}"
: "${RPM_URL:?Require rpm repository url}"
: "${RELEASELINE?Require rpm release line}"
: "${BASE:?Require base directory}"

# $$ Contains current pid
D="$AGENT_WORKDIR/$$"

# Convert string to array to correctly escape cli parameter
SSH_OPTS=($SSH_OPTS)

function clean() {
	rm -rf "$D"
}

function generateSite() {
	gpg --export -a --output "$D/repodata/repomd.xml.key" "${GPG_KEYNAME}"
	gpg --import-options show-only --import "$D/repodata/repomd.xml.key" >"$D/${ORGANIZATION}.key.info"

	"$BASE/bin/indexGenerator.py" \
		--distribution rpm \
		--gpg-key-info-file "${D}/${ORGANIZATION}.key.info" \
		--targetDir "$D"

	"$BASE/bin/branding.py" "$D"

	cp "$RPM" "$D/RPMS/noarch"

	cat >"$D/${ARTIFACTNAME}.repo" <<EOF
[${ARTIFACTNAME}]
name=${PRODUCTNAME}${RELEASELINE}
baseurl=${RPM_URL}
gpgkey=${RPM_URL}/repodata/repomd.xml.key
gpgcheck=1
repo_gpgcheck=1
EOF
}

function skipIfAlreadyPublished() {
	if ssh "${SSH_OPTS[@]}" "$PKGSERVER" test -e "${RPMDIR}/$(basename "$RPM")"; then
		echo "File already published, nothing else todo"
		exit 0

	fi
}

function init() {
	mkdir -p "$D/RPMS/noarch"

	mkdir -p "$RPMDIR/"
	# shellcheck disable=SC2029
	ssh "${SSH_OPTS[@]}" "$PKGSERVER" mkdir -p "'$RPMDIR/'"
}

function uploadPackage() {
	# Local
	rsync \
		--verbose \
		--times \
		--compress \
		--ignore-existing \
		--recursive \
		--progress \
		"$RPM" "$RPMDIR/"

	# Remote
	rsync \
		--archive \
		--times \
		--verbose \
		--compress \
		-e "ssh ${SSH_OPTS[*]}" \
		--ignore-existing \
		--progress \
		"${RPM}" "$PKGSERVER:${RPMDIR// /\\ }/"
}

function show() {
	echo "Parameters:"
	echo "RPM: $RPM"
	echo "RPMDIR: $RPMDIR"
	echo "RPM_WEBDIR: $RPM_WEBDIR"
	echo "SSH_OPTS: ${SSH_OPTS[*]}"
	echo "PKGSERVER: $PKGSERVER"
	echo "GPG_KEYNAME: $GPG_KEYNAME"
	echo "---"
}

function uploadSite() {
	pushd "$D"
	rsync \
		--archive \
		--times \
		--compress \
		--verbose \
		-e "ssh ${SSH_OPTS[*]}" \
		--exclude RPMS \
		--exclude "HEADER.html" \
		--exclude "FOOTER.html" \
		--progress \
		. "$PKGSERVER:${RPM_WEBDIR// /\\ }/"

	# generate index on the server
	ssh "${SSH_OPTS[@]}" "$PKGSERVER" createrepo --update -o "'$RPM_WEBDIR'" "'$RPMDIR/'"

	ssh "${SSH_OPTS[@]}" "$PKGSERVER" "cat $RPM_WEBDIR/repodata/repomd.xml" | \
	gpg \
		--batch \
		--pinentry-mode loopback \
		-u "$GPG_KEYNAME" \
		-a \
		--detach-sign \
		--passphrase-file "$GPG_PASSPHRASE_FILE" \
		--yes | \
	ssh "${SSH_OPTS[@]}" "$PKGSERVER" "cat > $RPM_WEBDIR/repodata/repomd.xml.asc"

	# Following html need to be located inside the binary directory
	rsync \
		--compress \
		--times \
		--verbose \
		--recursive \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
		. "$RPMDIR/"

	rsync \
		--archive \
		--times \
		--compress \
		--verbose \
		-e "ssh ${SSH_OPTS[*]}" \
		--include "HEADER.html" \
		--include "FOOTER.html" \
		--exclude "*" \
		--progress \
		. "$PKGSERVER:${RPMDIR// /\\ }/"
	popd
}

show
## Disabling this function allow us to recreate and sign the rpm repository.
# the rpm package won't be overrided as we use the parameter '--ignore-existing' when we upload it
#skipIfAlreadyPublished
init
uploadPackage
generateSite
uploadSite
clean

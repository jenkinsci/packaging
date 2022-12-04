#!/bin/sh

set -e

die() {
	echo "$(basename "$0"): $*" >&2
	exit 1
}

usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0") <from>"
	exit 2
}

NEW_JAVA_OPTS_DEFAULT="-Djava.awt.headless=true"
NEW_JENKINS_DEBUG_LEVEL_DEFAULT="5"
NEW_JENKINS_GROUP_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_HOME_DEFAULT="/var/lib/@@ARTIFACTNAME@@"
NEW_JENKINS_LOG_DEFAULT="/var/log/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.log"
NEW_JENKINS_MAXOPENFILES_DEFAULT="8192"
NEW_JENKINS_PORT_DEFAULT="@@PORT@@"
NEW_JENKINS_USER_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_WAR_DEFAULT="/usr/share/java/@@ARTIFACTNAME@@.war"
NEW_JENKINS_WEBROOT_DEFAULT="/var/cache/@@ARTIFACTNAME@@/war"

NEW_JAVA_HOME=""
NEW_JAVA_OPTS="${NEW_JAVA_OPTS_DEFAULT}"
NEW_JENKINS_DEBUG_LEVEL="${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}"
NEW_JENKINS_ENABLE_ACCESS_LOG=false
NEW_JENKINS_GROUP="${NEW_JENKINS_GROUP_DEFAULT}"
NEW_JENKINS_HOME="${NEW_JENKINS_HOME_DEFAULT}"
NEW_JENKINS_HTTP2_LISTEN_ADDRESS=""
NEW_JENKINS_HTTP2_PORT=""
NEW_JENKINS_HTTPS_KEYSTORE=""
NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD=""
NEW_JENKINS_HTTPS_LISTEN_ADDRESS=""
NEW_JENKINS_HTTPS_PORT=""
NEW_JENKINS_JAVA_CMD=""
NEW_JENKINS_LISTEN_ADDRESS=""
NEW_JENKINS_LOG="${NEW_JENKINS_LOG_DEFAULT}"
NEW_JENKINS_MAXOPENFILES="${NEW_JENKINS_MAXOPENFILES_DEFAULT}"
NEW_JENKINS_OPTS=""
NEW_JENKINS_PORT="${NEW_JENKINS_PORT_DEFAULT}"
NEW_JENKINS_PREFIX=""
NEW_JENKINS_UMASK=""
NEW_JENKINS_USER="${NEW_JENKINS_USER_DEFAULT}"
NEW_JENKINS_WAR="${NEW_JENKINS_WAR_DEFAULT}"
NEW_JENKINS_WEBROOT="${NEW_JENKINS_WEBROOT_DEFAULT}"

has_prefix=false

read_old_options() {
	# This could only be the case for deb
	if [ -n "${HTTP_PORT}" ] && [ "${HTTP_PORT}" -gt 0 ]; then
		# Normalize to rpm convention
		JENKINS_PORT="${HTTP_PORT}"
	fi

	if [ -n "${JENKINS_ARGS}" ]; then
		if [ -n "${NAME}" ]; then
			# For deb, these are all the arguments, except for the JENKINS_ENABLE_ACCESS_LOG additions
			webroot_quoted=false
			TMP_JENKINS_WEBROOT="$(printf '%s' "${JENKINS_ARGS}" | sed -n "s/.*--webroot=[\"']\\([[:alnum:][:space:]+,-\\./:;@\\_]*\\)[\"'].*/\\1/p")"
			[ -n "${TMP_JENKINS_WEBROOT}" ] && webroot_quoted=true
			[ -z "${TMP_JENKINS_WEBROOT}" ] && TMP_JENKINS_WEBROOT="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--webroot=\([[:alnum:][:punct:]]*\).*/\1/p')"

			log_quoted=false
			TMP_JENKINS_LOG="$(printf '%s' "${JENKINS_ARGS}" | sed -n "s/.*--logfile=[\"']\\([[:alnum:][:space:]+,-\\./:;@\\_]*\\)[\"'].*/\\1/p")"
			[ -n "${TMP_JENKINS_LOG}" ] && log_quoted=true
			[ -z "${TMP_JENKINS_LOG}" ] && TMP_JENKINS_LOG="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--logfile=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_PORT="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpPort=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_LISTEN_ADDRESS="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpListenAddress=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_HTTPS_PORT="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpsPort=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_HTTPS_LISTEN_ADDRESS="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpsListenAddress=\([[:alnum:][:punct:]]*\).*/\1/p')"

			keystore_quoted=false
			TMP_JENKINS_HTTPS_KEYSTORE="$(printf '%s' "${JENKINS_ARGS}" | sed -n "s/.*--httpsKeyStore=[\"']\\([[:alnum:][:space:]+,-\\./:;@\\_]*\\)[\"'].*/\\1/p")"
			[ -n "${TMP_JENKINS_HTTPS_KEYSTORE}" ] && keystore_quoted=true
			[ -z "${TMP_JENKINS_HTTPS_KEYSTORE}" ] && TMP_JENKINS_HTTPS_KEYSTORE="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpsKeyStore=\([[:alnum:][:punct:]]*\).*/\1/p')"

			keystore_password_quoted=false
			TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD="$(printf '%s' "${JENKINS_ARGS}" | sed -n "s/.*--httpsKeyStorePassword=[\"']\\([[:alnum:][:space:]+,-\\./:;@\\_]*\\)[\"'].*/\\1/p")"
			[ -n "${TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ] && keystore_password_quoted=true
			[ -z "${TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ] && TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--httpsKeyStorePassword=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_HTTP2_PORT="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--http2Port=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_HTTP2_LISTEN_ADDRESS="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--http2ListenAddress=\([[:alnum:][:punct:]]*\).*/\1/p')"

			TMP_JENKINS_DEBUG_LEVEL="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--debug=\([[:alnum:][:punct:]]*\).*/\1/p')"

			prefix_quoted=false
			TMP_PREFIX="$(printf '%s' "${JENKINS_ARGS}" | sed -n "s/.*--prefix=[\"']\\([[:alnum:][:space:]+,-\\./:;@\\_]*\\)[\"'].*/\\1/p")"
			[ -n "${TMP_PREFIX}" ] && prefix_quoted=true
			[ -z "${TMP_PREFIX}" ] && TMP_PREFIX="$(printf '%s' "${JENKINS_ARGS}" | sed -n 's/.*--prefix=\([[:alnum:][:punct:]]*\).*/\1/p')"

			[ -n "${TMP_JENKINS_WEBROOT}" ] && JENKINS_WEBROOT="${TMP_JENKINS_WEBROOT}"
			[ -n "${TMP_JENKINS_LOG}" ] && JENKINS_LOG="${TMP_JENKINS_LOG}"
			[ -n "${TMP_JENKINS_PORT}" ] && JENKINS_PORT="${TMP_JENKINS_PORT}"
			[ -n "${TMP_JENKINS_LISTEN_ADDRESS}" ] && JENKINS_LISTEN_ADDRESS="${TMP_JENKINS_LISTEN_ADDRESS}"
			[ -n "${TMP_JENKINS_HTTPS_PORT}" ] && JENKINS_HTTPS_PORT="${TMP_JENKINS_HTTPS_PORT}"
			[ -n "${TMP_JENKINS_HTTPS_LISTEN_ADDRESS}" ] && JENKINS_HTTPS_LISTEN_ADDRESS="${TMP_JENKINS_HTTPS_LISTEN_ADDRESS}"
			[ -n "${TMP_JENKINS_HTTPS_KEYSTORE}" ] && JENKINS_HTTPS_KEYSTORE="${TMP_JENKINS_HTTPS_KEYSTORE}"
			[ -n "${TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ] && JENKINS_HTTPS_KEYSTORE_PASSWORD="${TMP_JENKINS_HTTPS_KEYSTORE_PASSWORD}"
			[ -n "${TMP_JENKINS_HTTP2_PORT}" ] && JENKINS_HTTP2_PORT="${TMP_JENKINS_HTTP2_PORT}"
			[ -n "${TMP_JENKINS_HTTP2_LISTEN_ADDRESS}" ] && JENKINS_HTTP2_LISTEN_ADDRESS="${TMP_JENKINS_HTTP2_LISTEN_ADDRESS}"
			[ -n "${TMP_JENKINS_DEBUG_LEVEL}" ] && JENKINS_DEBUG_LEVEL="${TMP_JENKINS_DEBUG_LEVEL}"
			[ -n "${TMP_PREFIX}" ] && PREFIX="${TMP_PREFIX}"
			[ -n "${TMP_PREFIX}" ] && has_prefix=true

			if $webroot_quoted; then
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed "s/--webroot=[\"'][[:alnum:][:space:]+,-\\./:;@\\_]*[\"']//g")"
			else
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--webroot=[[:alnum:][:punct:]]*//g')"
			fi

			if $log_quoted; then
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed "s/--logfile=[\"'][[:alnum:][:space:]+,-\\./:;@\\_]*[\"']//g")"
			else
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--logfile=[[:alnum:][:punct:]]*//g')"
			fi

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpPort=[[:alnum:][:punct:]]*//g')"

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpListenAddress=[[:alnum:][:punct:]]*//g')"

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpsPort=[[:alnum:][:punct:]]*//g')"

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpsListenAddress=[[:alnum:][:punct:]]*//g')"

			if $keystore_quoted; then
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed "s/--httpsKeyStore=[\"'][[:alnum:][:space:]+,-\\./:;@\\_]*[\"']//g")"
			else
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpsKeyStore=[[:alnum:][:punct:]]*//g')"
			fi

			if $keystore_password_quoted; then
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed "s/--httpsKeyStorePassword=[\"'][[:alnum:][:space:]+,-\\./:;@\\_]*[\"']//g")"
			else
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--httpsKeyStorePassword=[[:alnum:][:punct:]]*//g')"
			fi

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--http2Port=[[:alnum:][:punct:]]*//g')"

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--http2ListenAddress=[[:alnum:][:punct:]]*//g')"

			JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--debug=[[:alnum:][:punct:]]*//g')"

			if $prefix_quoted; then
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed "s/--prefix=[\"'][[:alnum:][:space:]+,-\\./:;@\\_]*[\"']//g")"
			else
				JENKINS_ARGS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/--prefix=[[:alnum:][:punct:]]*//g')"
			fi

			# All that remains are the extra arguments
			NEW_JENKINS_OPTS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/^[[:space:]]*//g')"
			NEW_JENKINS_OPTS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/[[:space:]]*$//g')"
		else
			# For rpm and suse, these are extra arguments
			NEW_JENKINS_OPTS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/^[[:space:]]*//g')"
			NEW_JENKINS_OPTS="$(printf '%s' "${JENKINS_ARGS}" | sed 's/[[:space:]]*$//g')"
		fi
	fi

	if [ -n "${JENKINS_USER}" ]; then
		NEW_JENKINS_USER="${JENKINS_USER}"
	fi

	if [ -n "${JENKINS_GROUP}" ]; then
		NEW_JENKINS_GROUP="${JENKINS_GROUP}"
	fi

	if [ -n "${JENKINS_HOME}" ] && [ -d "${JENKINS_HOME}" ]; then
		NEW_JENKINS_HOME="${JENKINS_HOME}"
	fi

	if [ -n "${JENKINS_WAR}" ] && [ -f "${JENKINS_WAR}" ]; then
		NEW_JENKINS_WAR="${JENKINS_WAR}"
	fi
	if [ "${NEW_JENKINS_WAR}" = "/usr/share/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.war" ]; then
		# deb
		NEW_JENKINS_WAR="${NEW_JENKINS_WAR_DEFAULT}"
	elif [ "${NEW_JENKINS_WAR}" = "/usr/lib/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.war" ]; then
		# rpm
		NEW_JENKINS_WAR="${NEW_JENKINS_WAR_DEFAULT}"
	fi

	if [ -n "${JENKINS_WEBROOT}" ] && [ -d "${JENKINS_WEBROOT}" ]; then
		NEW_JENKINS_WEBROOT="${JENKINS_WEBROOT}"
	fi

	if [ -n "${JENKINS_LOG}" ]; then
		NEW_JENKINS_LOG="${JENKINS_LOG}"
	fi

	if [ -n "${JENKINS_JAVA_HOME}" ] && [ -d "${JENKINS_JAVA_HOME}" ]; then
		NEW_JAVA_HOME="${JENKINS_JAVA_HOME}"
	fi

	if [ -n "${JENKINS_JAVA_CMD}" ] && [ -x "${JENKINS_JAVA_CMD}" ]; then
		NEW_JENKINS_JAVA_CMD="${JENKINS_JAVA_CMD}"
	fi

	if [ -n "${JAVA_ARGS}" ]; then
		NEW_JAVA_OPTS="${JAVA_ARGS}"
	elif [ -n "${JENKINS_JAVA_OPTIONS}" ]; then
		NEW_JAVA_OPTS="${JENKINS_JAVA_OPTIONS}"
	fi

	if [ -n "${JENKINS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_LISTEN_ADDRESS="${JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_PORT}" ] && [ "${JENKINS_PORT}" -gt 0 ]; then
		NEW_JENKINS_PORT="${JENKINS_PORT}"
	fi

	if [ -n "${JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_HTTPS_LISTEN_ADDRESS="${JENKINS_HTTPS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTPS_PORT}" ] && [ "${JENKINS_HTTPS_PORT}" -gt 0 ]; then
		NEW_JENKINS_HTTPS_PORT="${JENKINS_HTTPS_PORT}"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE}" ] && [ -f "${JENKINS_HTTPS_KEYSTORE}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE="${JENKINS_HTTPS_KEYSTORE}"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD="${JENKINS_HTTPS_KEYSTORE_PASSWORD}"
	fi

	if [ -n "${JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_HTTP2_LISTEN_ADDRESS="${JENKINS_HTTP2_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTP2_PORT}" ] && [ "${JENKINS_HTTP2_PORT}" -gt 0 ]; then
		NEW_JENKINS_HTTP2_PORT="${JENKINS_HTTP2_PORT}"
	fi

	if [ -n "${JENKINS_DEBUG_LEVEL}" ] && [ "${JENKINS_DEBUG_LEVEL}" -gt 0 ]; then
		NEW_JENKINS_DEBUG_LEVEL="${JENKINS_DEBUG_LEVEL}"
	fi

	if [ -n "${JENKINS_ENABLE_ACCESS_LOG}" ] && [ "${JENKINS_ENABLE_ACCESS_LOG}" = "yes" ]; then
		NEW_JENKINS_ENABLE_ACCESS_LOG=true
	fi

	if [ -n "${PREFIX}" ] && $has_prefix; then
		NEW_JENKINS_PREFIX="${PREFIX}"
	fi

	if [ -n "${MAXOPENFILES}" ] && [ "${MAXOPENFILES}" -gt 0 ]; then
		NEW_JENKINS_MAXOPENFILES="${MAXOPENFILES}"
	fi

	if [ -n "${UMASK}" ]; then
		NEW_JENKINS_UMASK="${UMASK}"
	fi
}

migrate_options() {
	if [ -f /etc/systemd/system/@@ARTIFACTNAME@@.service.d/override.conf ]; then
		return
	fi

	tmpfile=$(mktemp)
	edited=false

	echo '[Service]' >>"${tmpfile}"

	if [ "${NEW_JENKINS_USER}" != "${NEW_JENKINS_USER_DEFAULT}" ]; then
		NEW_JENKINS_USER="$(printf '%s' "${NEW_JENKINS_USER}" | sed -e 's/"/\\"/g')"
		echo "User=${NEW_JENKINS_USER}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_GROUP}" != "${NEW_JENKINS_GROUP_DEFAULT}" ]; then
		NEW_JENKINS_GROUP="$(printf '%s' "${NEW_JENKINS_GROUP}" | sed -e 's/"/\\"/g')"
		echo "Group=${NEW_JENKINS_GROUP}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_HOME}" != "${NEW_JENKINS_HOME_DEFAULT}" ]; then
		NEW_JENKINS_HOME="$(printf '%s' "${NEW_JENKINS_HOME}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HOME=${NEW_JENKINS_HOME}\"" >>"${tmpfile}"
		echo "WorkingDirectory=${NEW_JENKINS_HOME}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_WAR}" != "${NEW_JENKINS_WAR_DEFAULT}" ]; then
		NEW_JENKINS_WAR="$(printf '%s' "${NEW_JENKINS_WAR}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_WAR=${NEW_JENKINS_WAR}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_WEBROOT}" != "${NEW_JENKINS_WEBROOT_DEFAULT}" ]; then
		NEW_JENKINS_WEBROOT="$(printf '%s' "${NEW_JENKINS_WEBROOT}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_WEBROOT=${NEW_JENKINS_WEBROOT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_LOG}" != "${NEW_JENKINS_LOG_DEFAULT}" ]; then
		NEW_JENKINS_LOG="$(printf '%s' "${NEW_JENKINS_LOG}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_LOG=${NEW_JENKINS_LOG}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JAVA_HOME}" ]; then
		NEW_JENKINS_HOME="$(printf '%s' "${NEW_JENKINS_HOME}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JAVA_HOME=${NEW_JAVA_HOME}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_JAVA_CMD}" ]; then
		NEW_JENKINS_JAVA_CMD="$(printf '%s' "${NEW_JENKINS_JAVA_CMD}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_JAVA_CMD=${NEW_JENKINS_JAVA_CMD}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JAVA_OPTS}" != "${NEW_JAVA_OPTS_DEFAULT}" ]; then
		NEW_JAVA_OPTS="$(printf '%s' "${NEW_JAVA_OPTS}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JAVA_OPTS=${NEW_JAVA_OPTS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_LISTEN_ADDRESS="$(printf '%s' "${NEW_JENKINS_LISTEN_ADDRESS}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_LISTEN_ADDRESS=${NEW_JENKINS_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	privileged_port=false

	if [ "${NEW_JENKINS_PORT}" != "${NEW_JENKINS_PORT_DEFAULT}" ]; then
		[ "${NEW_JENKINS_PORT}" -lt 1024 ] && privileged_port=true
		NEW_JENKINS_PORT="$(printf '%s' "${NEW_JENKINS_PORT}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_PORT=${NEW_JENKINS_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_HTTPS_LISTEN_ADDRESS="$(printf '%s' "${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTPS_LISTEN_ADDRESS=${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_PORT}" ]; then
		[ "${NEW_JENKINS_HTTPS_PORT}" -lt 1024 ] && privileged_port=true
		NEW_JENKINS_HTTPS_PORT="$(printf '%s' "${NEW_JENKINS_HTTPS_PORT}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTPS_PORT=${NEW_JENKINS_HTTPS_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE="$(printf '%s' "${NEW_JENKINS_HTTPS_KEYSTORE}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTPS_KEYSTORE=${NEW_JENKINS_HTTPS_KEYSTORE}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD="$(printf '%s' "${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTPS_KEYSTORE_PASSWORD=${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_HTTP2_LISTEN_ADDRESS="$(printf '%s' "${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTP2_LISTEN_ADDRESS=${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTP2_PORT}" ]; then
		[ "${NEW_JENKINS_HTTP2_PORT}" -lt 1024 ] && privileged_port=true
		NEW_JENKINS_HTTP2_PORT="$(printf '%s' "${NEW_JENKINS_HTTP2_PORT}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_HTTP2_PORT=${NEW_JENKINS_HTTP2_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if $privileged_port; then
		echo "AmbientCapabilities=CAP_NET_BIND_SERVICE" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_DEBUG_LEVEL}" != "${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}" ]; then
		NEW_JENKINS_DEBUG_LEVEL="$(printf '%s' "${NEW_JENKINS_DEBUG_LEVEL}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_DEBUG_LEVEL=${NEW_JENKINS_DEBUG_LEVEL}\"" >>"${tmpfile}"
		edited=true
	fi

	if $NEW_JENKINS_ENABLE_ACCESS_LOG; then
		echo "Environment=\"JENKINS_ENABLE_ACCESS_LOG=${NEW_JENKINS_ENABLE_ACCESS_LOG}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_PREFIX}" ]; then
		NEW_JENKINS_PREFIX="$(printf '%s' "${NEW_JENKINS_PREFIX}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_PREFIX=${NEW_JENKINS_PREFIX}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_OPTS}" ]; then
		NEW_JENKINS_OPTS="$(printf '%s' "${NEW_JENKINS_OPTS}" | sed -e 's/"/\\"/g')"
		echo "Environment=\"JENKINS_OPTS=${NEW_JENKINS_OPTS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_MAXOPENFILES}" != "${NEW_JENKINS_MAXOPENFILES_DEFAULT}" ]; then
		NEW_JENKINS_MAXOPENFILES="$(printf '%s' "${NEW_JENKINS_MAXOPENFILES}" | sed -e 's/"/\\"/g')"
		echo "LimitNOFILE=${NEW_JENKINS_MAXOPENFILES}" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_UMASK}" ]; then
		NEW_JENKINS_UMASK="$(printf '%s' "${NEW_JENKINS_UMASK}" | sed -e 's/"/\\"/g')"
		echo "UMask=${NEW_JENKINS_UMASK}" >>"${tmpfile}"
		edited=true
	fi

	if $edited; then
		mkdir -p /etc/systemd/system/@@ARTIFACTNAME@@.service.d
		mv "${tmpfile}" /etc/systemd/system/@@ARTIFACTNAME@@.service.d/override.conf
	else
		rm -f "${tmpfile}"
	fi
}

main() {
	from=$1

	[ -f "${from}" ] || die "${from} does not exist"
	. "${from}"
	read_old_options
	migrate_options
}

[ $# -gt 1 ] && usage "too many arguments specified"
[ $# -lt 1 ] && usage "too few arguments specified"
main "$1"

exit 0

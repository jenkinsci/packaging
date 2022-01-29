#!/bin/sh

die() {
	echo "$(basename "$0"): $*" >&2
	exit 1
}

usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0")"
	exit 2
}

check_env() {
	required=true
	for var in "$@"; do
		if [ "${var}" = '--' ]; then
			required=false
			continue
		fi

		val=$(eval echo "\$${var}")
		if $required && [ -z "${val}" ]; then
			die "check_env: ${var} must be non-empty"
		fi
	done
}

infer_java_cmd() {
	if [ -n "${JENKINS_JAVA_CMD}" ] && [ -x "${JENKINS_JAVA_CMD}" ]; then
		return 0
	fi

	if [ -n "${JAVA_HOME}" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
		JENKINS_JAVA_CMD="${JAVA_HOME}/bin/java"
		return 0
	fi

	JENKINS_JAVA_CMD="$(command -v java)" || return "$?"
}

check_java_version() {
	java_version=$("${JENKINS_JAVA_CMD}" -version 2>&1 |
		sed -n ';s/.* version "\([0-9]\{2,\}\|[0-9]\.[0-9]\)\..*".*/\1/p;')

	if [ -z "${java_version}" ]; then
		return 1
	elif [ "${java_version}" != "11" ] && [ "${java_version}" != "1.8" ]; then
		return 1
	else
		return 0
	fi
}

infer_jenkins_opts() {
	inferred_jenkins_opts=""

	if [ -n "${JENKINS_WEBROOT}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --webroot='${JENKINS_WEBROOT}'"
	fi

	if [ -n "${JENKINS_LOG}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --logfile='${JENKINS_LOG}'"
	fi

	if [ -n "${JENKINS_PORT}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpPort=${JENKINS_PORT}"
	fi

	if [ -n "${JENKINS_LISTEN_ADDRESS}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpListenAddress=${JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTPS_PORT}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpsPort=${JENKINS_HTTPS_PORT}"
	fi

	if [ -n "${JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpsListenAddress=${JENKINS_HTTPS_LISTEN_ADDRESS}"
	fi

	if [ -n "${CREDENTIALS_DIRECTORY}" ] && [ -f "${CREDENTIALS_DIRECTORY}/keystore.jks" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpsKeyStore='${CREDENTIALS_DIRECTORY}/keystore.jks'"
	fi

	if [ -n "${CREDENTIALS_DIRECTORY}" ] && [ -f "${CREDENTIALS_DIRECTORY}/keystore.pass" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --httpsKeyStorePassword='$(cat "${CREDENTIALS_DIRECTORY}/keystore.pass")'"
	fi

	if [ -n "${JENKINS_HTTP2_PORT}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --http2Port=${JENKINS_HTTP2_PORT}"
	fi

	if [ -n "${JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --http2ListenAddress=${JENKINS_HTTP2_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_DEBUG_LEVEL}" ] && [ "${JENKINS_DEBUG_LEVEL}" -ne 5 ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --debug=${JENKINS_DEBUG_LEVEL}"
	fi

	if [ -n "${JENKINS_EXTRA_LIB_FOLDER}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --extraLibFolder='${JENKINS_EXTRA_LIB_FOLDER}'"
	fi

	if [ -n "${JENKINS_PREFIX}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --prefix='${JENKINS_PREFIX}'"
	fi

	if [ -n "${JENKINS_OPTS}" ]; then
		inferred_jenkins_opts="${inferred_jenkins_opts} ${JENKINS_OPTS}"
	fi

	if [ -n "${JENKINS_ENABLE_ACCESS_LOG}" ] && $JENKINS_ENABLE_ACCESS_LOG; then
		inferred_jenkins_opts="${inferred_jenkins_opts} --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger"
		inferred_jenkins_opts="${inferred_jenkins_opts} --simpleAccessLogger.format=combined"
		inferred_jenkins_opts="${inferred_jenkins_opts} --simpleAccessLogger.file='/var/log/@@ARTIFACTNAME@@/access_log'"
	fi
}

main() {
	if [ -n "${JENKINS_HOME}" ]; then
		[ -d "${JENKINS_HOME}" ] || die "${JENKINS_HOME} is not a directory"
	fi
	[ -f "${JENKINS_WAR}" ] || die "${JENKINS_WAR} is not a file"

	infer_java_cmd || die 'failed to find a valid Java installation'

	check_java_version ||
		die "invalid java version: $("${JENKINS_JAVA_CMD}" -version)"

	infer_jenkins_opts

	# TODO unsetenv JAVA_OPTS
	unset JENKINS_DEBUG_LEVEL
	unset JENKINS_ENABLE_ACCESS_LOG
	unset JENKINS_EXTRA_LIB_FOLDER
	unset JENKINS_HTTP2_LISTEN_ADDRESS
	unset JENKINS_HTTP2_PORT
	unset JENKINS_HTTPS_KEYSTORE
	unset JENKINS_HTTPS_KEYSTORE_PASSWORD
	unset JENKINS_HTTPS_LISTEN_ADDRESS
	unset JENKINS_HTTPS_PORT
	# TODO unsetenv JENKINS_JAVA_CMD
	unset JENKINS_LISTEN_ADDRESS
	unset JENKINS_LOG
	unset JENKINS_OPTS
	unset JENKINS_PORT
	unset JENKINS_PREFIX
	# TODO unsetenv JENKINS_WAR
	unset JENKINS_WEBROOT
	eval exec \
		"${JENKINS_JAVA_CMD}" \
		${JAVA_OPTS} \
		-jar "${JENKINS_WAR}" \
		${inferred_jenkins_opts}
}

[ $# -ne 0 ] && usage 'too many arguments specified'

if [ -z "${JENKINS_WAR}" ]; then
	JENKINS_WAR=/usr/lib/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.war
fi

check_env \
	JENKINS_WAR \
	-- \
	JAVA_HOME \
	JENKINS_DEBUG_LEVEL \
	JENKINS_ENABLE_ACCESS_LOG \
	JENKINS_EXTRA_LIB_FOLDER \
	JENKINS_HOME \
	JENKINS_HTTP2_LISTEN_ADDRESS \
	JENKINS_HTTP2_PORT \
	JENKINS_HTTPS_KEYSTORE \
	JENKINS_HTTPS_KEYSTORE_PASSWORD \
	JENKINS_HTTPS_LISTEN_ADDRESS \
	JAVA_OPTS \
	JENKINS_HTTPS_PORT \
	JENKINS_JAVA_CMD \
	JENKINS_LISTEN_ADDRESS \
	JENKINS_LOG \
	JENKINS_OPTS \
	JENKINS_PORT \
	JENKINS_PREFIX \
	JENKINS_WEBROOT

main

exit 0

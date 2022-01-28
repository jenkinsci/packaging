#!/bin/sh

die() {
	echo "$(basename "$0"): $*" >&2
	exit 2
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

infer_jenkins_args() {
	JENKINS_ARGS="--webroot='${JENKINS_WEBROOT}'"

	if [ -n "${JENKINS_LOG}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --logfile='${JENKINS_LOG}'"
	fi

	if [ -n "${JENKINS_PORT}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpPort=${JENKINS_PORT}"
	fi

	if [ -n "${JENKINS_LISTEN_ADDRESS}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpListenAddress=${JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTPS_PORT}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpsPort=${JENKINS_HTTPS_PORT}"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpsKeyStore='${JENKINS_HTTPS_KEYSTORE}'"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpsKeyStorePassword='${JENKINS_HTTPS_KEYSTORE_PASSWORD}'"
	fi

	if [ -n "${JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --httpsListenAddress=${JENKINS_HTTPS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTP2_PORT}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --http2Port=${JENKINS_HTTP2_PORT}"
	fi

	if [ -n "${JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --http2ListenAddress=${JENKINS_HTTP2_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_DEBUG_LEVEL}" ] && [ "${JENKINS_DEBUG_LEVEL}" -ne 5 ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --debug=${JENKINS_DEBUG_LEVEL}"
	fi

	if [ -n "${JENKINS_EXTRA_LIB_FOLDER}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --extraLibFolder='${JENKINS_EXTRA_LIB_FOLDER}'"
	fi

	if [ -n "${JENKINS_PREFIX}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --prefix='${JENKINS_PREFIX}'"
	fi

	if [ -n "${JENKINS_EXTRA_ARGS}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} ${JENKINS_EXTRA_ARGS}"
	fi

	if [ -n "${JENKINS_ENABLE_ACCESS_LOG}" ]; then
		JENKINS_ARGS="${JENKINS_ARGS} --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger"
		JENKINS_ARGS="${JENKINS_ARGS} --simpleAccessLogger.format=combined"
		JENKINS_ARGS="${JENKINS_ARGS} --simpleAccessLogger.file='/var/log/@@ARTIFACTNAME@@/access_log'"
	fi
}

main() {
	[ -d "${JENKINS_HOME}" ] || die "${JENKINS_HOME} is not a directory"
	[ -f "${JENKINS_WAR}" ] || die "${JENKINS_WAR} is not a file"

	infer_java_cmd || die 'failed to find a valid Java installation'

	check_java_version ||
		die "invalid java version: $("${JENKINS_JAVA_CMD}" -version)"

	if [ -z "${JENKINS_ARGS}" ]; then
		infer_jenkins_args
	else
		die "JENKINS_ARGS must be unset but was set to ${JENKINS_ARGS}"
	fi

	# TODO unsetenv JENKINS_ARGS
	unset JENKINS_DEBUG_LEVEL
	unset JENKINS_ENABLE_ACCESS_LOG
	unset JENKINS_EXTRA_ARGS
	unset JENKINS_EXTRA_LIB_FOLDER
	unset JENKINS_HTTP2_LISTEN_ADDRESS
	unset JENKINS_HTTP2_PORT
	unset JENKINS_HTTPS_KEYSTORE
	unset JENKINS_HTTPS_KEYSTORE_PASSWORD
	unset JENKINS_HTTPS_LISTEN_ADDRESS
	unset JENKINS_HTTPS_PORT
	# TODO unsetenv JENKINS_JAVA_ARGS
	# TODO unsetenv JENKINS_JAVA_CMD
	unset JENKINS_LISTEN_ADDRESS
	unset JENKINS_LOG
	unset JENKINS_PORT
	unset JENKINS_PREFIX
	# TODO unsetenv JENKINS_WAR
	unset JENKINS_WEBROOT
	exec \
		"${JENKINS_JAVA_CMD}" \
		${JENKINS_JAVA_ARGS} \
		-jar "${JENKINS_WAR}" \
		${JENKINS_ARGS}
}

[ $# -gt 0 ] && usage 'too many arguments specified'

check_env \
	JENKINS_HOME \
	JENKINS_WAR \
	JENKINS_WEBROOT \
	-- \
	JAVA_HOME \
	JENKINS_DEBUG_LEVEL \
	JENKINS_ENABLE_ACCESS_LOG \
	JENKINS_EXTRA_ARGS \
	JENKINS_EXTRA_LIB_FOLDER \
	JENKINS_HTTP2_LISTEN_ADDRESS \
	JENKINS_HTTP2_PORT \
	JENKINS_HTTPS_KEYSTORE \
	JENKINS_HTTPS_KEYSTORE_PASSWORD \
	JENKINS_HTTPS_LISTEN_ADDRESS \
	JENKINS_HTTPS_PORT \
	JENKINS_JAVA_ARGS \
	JENKINS_JAVA_CMD \
	JENKINS_LISTEN_ADDRESS \
	JENKINS_LOG \
	JENKINS_PORT \
	JENKINS_PREFIX

main

exit 0

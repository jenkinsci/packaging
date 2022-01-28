#!/bin/sh

die() {
	echo "$(basename "$0"): $*" >&2
	exit 2
}

usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0") <from> <to>"
	exit 2
}

# Options used in inferring JENKINS_ARGS
NEW_JENKINS_DEBUG_LEVEL_DEFAULT="5"
NEW_JENKINS_LOG_DEFAULT="/var/log/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.log"
NEW_JENKINS_PORT_DEFAULT="@@PORT@@"
NEW_JENKINS_WEBROOT_DEFAULT="/var/cache/@@ARTIFACTNAME@@/war"
NEW_JENKINS_DEBUG_LEVEL="${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}"
NEW_JENKINS_ENABLE_ACCESS_LOG=false
NEW_JENKINS_EXTRA_ARGS=""
NEW_JENKINS_EXTRA_LIB_FOLDER=""
NEW_JENKINS_HTTP2_LISTEN_ADDRESS=""
NEW_JENKINS_HTTP2_PORT=""
NEW_JENKINS_HTTPS_KEYSTORE=""
NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD=""
NEW_JENKINS_HTTPS_LISTEN_ADDRESS=""
NEW_JENKINS_HTTPS_PORT=""
NEW_JENKINS_LISTEN_ADDRESS=""
NEW_JENKINS_LOG="${NEW_JENKINS_LOG_DEFAULT}"
NEW_JENKINS_PORT="${NEW_JENKINS_PORT_DEFAULT}"
NEW_JENKINS_PREFIX=""
NEW_JENKINS_WEBROOT="${NEW_JENKINS_WEBROOT_DEFAULT}"

# Top-level options
NEW_JENKINS_GROUP_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_HOME_DEFAULT="/var/lib/@@ARTIFACTNAME@@"
NEW_JENKINS_JAVA_ARGS_DEFAULT="-Dhudson.lifecycle=hudson.lifecycle.ExitLifecycle -Djava.awt.headless=true"
NEW_JENKINS_JAVA_CMD_DEFAULT="/usr/bin/java"
NEW_JENKINS_MAXOPENFILES_DEFAULT="8192"
NEW_JENKINS_UMASK_DEFAULT="0022"
NEW_JENKINS_USER_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_WAR_DEFAULT="/usr/lib/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.war"
NEW_JENKINS_ARGS=""
NEW_JENKINS_GROUP="${NEW_JENKINS_GROUP_DEFAULT}"
NEW_JENKINS_HOME="${NEW_JENKINS_HOME_DEFAULT}"
NEW_JENKINS_JAVA_ARGS="${NEW_JENKINS_JAVA_ARGS_DEFAULT}"
NEW_JENKINS_JAVA_CMD="${NEW_JENKINS_JAVA_CMD_DEFAULT}"
NEW_JENKINS_JAVA_HOME="" # if set, check for java and set as path and java_cmd
NEW_JENKINS_MAXOPENFILES="${NEW_JENKINS_MAXOPENFILES_DEFAULT}"
NEW_JENKINS_UMASK="${NEW_JENKINS_UMASK_DEFAULT}"
NEW_JENKINS_USER="${NEW_JENKINS_USER_DEFAULT}"
NEW_JENKINS_WAR="${NEW_JENKINS_WAR_DEFAULT}"

read_old_options() {
	if [ -n "${JENKINS_ARGS}" ]; then
		if [ -n "${NAME}" ]; then
			# For deb, these are all the arguments, except for the JENKINS_ENABLE_ACCESS_LOG additions
			NEW_JENKINS_ARGS="${JENKINS_ARGS}"
		else
			# For rpm and suse, these are extra arguments
			NEW_JENKINS_EXTRA_ARGS="${JENKINS_ARGS}"
		fi
	fi

	if [ -n "${JENKINS_DEBUG_LEVEL}" ] && [ "${JENKINS_DEBUG_LEVEL}" -gt 0 ]; then
		NEW_JENKINS_DEBUG_LEVEL="${JENKINS_DEBUG_LEVEL}"
	fi

	if [ -n "${JENKINS_ENABLE_ACCESS_LOG}" ] && [ "${JENKINS_ENABLE_ACCESS_LOG}" = "yes" ]; then
		NEW_JENKINS_ENABLE_ACCESS_LOG=true
	fi

	if [ -n "${JENKINS_EXTRA_LIB_FOLDER}" ] && [ -d "${JENKINS_EXTRA_LIB_FOLDER}" ]; then
		NEW_JENKINS_EXTRA_LIB_FOLDER="${JENKINS_EXTRA_LIB_FOLDER}"
	fi

	if [ -n "${JENKINS_GROUP}" ]; then
		NEW_JENKINS_GROUP="${JENKINS_GROUP}"
	fi

	if [ -n "${JENKINS_HOME}" ] && [ -d "${JENKINS_HOME}" ]; then
		NEW_JENKINS_HOME="${JENKINS_HOME}"
	fi

	if [ -n "${JENKINS_HTTP2_PORT}" ] && [ "${JENKINS_HTTP2_PORT}" -gt 0 ]; then
		NEW_JENKINS_HTTP2_PORT="${JENKINS_HTTP2_PORT}"
	fi

	if [ -n "${JENKINS_HTTP2_LISTEN_ADDRESS}" ] && [ "${JENKINS_HTTP2_LISTEN_ADDRESS}" -gt 0 ]; then
		NEW_JENKINS_HTTP2_LISTEN_ADDRESS="${JENKINS_HTTP2_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE}" ] && [ -f "${JENKINS_HTTPS_KEYSTORE}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE="${JENKINS_HTTPS_KEYSTORE}"
	fi

	if [ -n "${JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD="${JENKINS_HTTPS_KEYSTORE_PASSWORD}"
	fi

	if [ -n "${JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_HTTPS_LISTEN_ADDRESS="${JENKINS_HTTPS_LISTEN_ADDRESS}"
	fi

	if [ -n "${JENKINS_HTTPS_PORT}" ] && [ "${JENKINS_HTTPS_PORT}" -gt 0 ]; then
		NEW_JENKINS_HTTPS_PORT="${JENKINS_HTTPS_PORT}"
	fi

	if [ -n "${JAVA_ARGS}" ]; then
		NEW_JENKINS_JAVA_ARGS="${JAVA_ARGS}"
	elif [ -n "${JENKINS_JAVA_OPTIONS}" ]; then
		NEW_JENKINS_JAVA_ARGS="${JENKINS_JAVA_OPTIONS}"
	fi

	if [ -n "${JENKINS_JAVA_CMD}" ] && [ -x "${JENKINS_JAVA_CMD}" ]; then
		NEW_JENKINS_JAVA_CMD="${JENKINS_JAVA_CMD}"
	fi

	if [ -n "${JENKINS_JAVA_HOME}" ] && [ -d "${JENKINS_JAVA_HOME}" ]; then
		NEW_JENKINS_JAVA_HOME="${JENKINS_JAVA_HOME}"
	fi

	if [ -n "${JENKINS_LOG}" ]; then
		NEW_JENKINS_LOG="${JENKINS_LOG}"
	fi

	if [ -n "${JENKINS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_LISTEN_ADDRESS="${JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${MAXOPENFILES}" ] && [ "${MAXOPENFILES}" -gt 0 ]; then
		NEW_JENKINS_MAXOPENFILES="${MAXOPENFILES}"
	fi

	if [ -n "${HTTP_PORT}" ] && [ "${HTTP_PORT}" -gt 0 ]; then
		NEW_JENKINS_PORT="${HTTP_PORT}"
	elif [ -n "${JENKINS_PORT}" ] && [ "${JENKINS_PORT}" -gt 0 ]; then
		NEW_JENKINS_PORT="${JENKINS_PORT}"
	fi

	if [ -n "${PREFIX}" ]; then
		NEW_JENKINS_PREFIX="${PREFIX}"
	fi

	if [ -n "${UMASK}" ]; then
		NEW_JENKINS_UMASK="${UMASK}"
	fi

	if [ -n "${JENKINS_USER}" ]; then
		NEW_JENKINS_USER="${JENKINS_USER}"
	fi

	if [ -n "${JENKINS_WAR}" ] && [ -f "${JENKINS_WAR}" ]; then
		NEW_JENKINS_WAR="${JENKINS_WAR}"
	fi

	if [ -n "${JENKINS_WEBROOT}" ] && [ -d "${JENKINS_WEBROOT}" ]; then
		NEW_JENKINS_WEBROOT="${JENKINS_WEBROOT}"
	fi
}

infer_jenkins_args() {
	if [ -n "${NEW_JENKINS_ARGS}" ]; then
		# TODO add '--logfile' to the front if it's missing
		if $NEW_JENKINS_ENABLE_ACCESS_LOG; then
			NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/@@ARTIFACTNAME@@/access_log"
		fi
		return
	fi

	NEW_JENKINS_ARGS="--logfile=${NEW_JENKINS_LOGFILE}"
	NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --webroot=${NEW_JENKINS_WEBROOT}"
	NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpPort=${NEW_JENKINS_PORT}"

	if [ -n "${NEW_JENKINS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpListenAddress=${NEW_JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${NEW_JENKINS_HTTPS_PORT}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpsPort=${NEW_JENKINS_HTTPS_PORT}"
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpsKeyStore='${NEW_JENKINS_HTTPS_KEYSTORE}'"
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpsKeyStorePassword='${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}'"
	fi

	if [ -n "${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --httpsListenAddress=${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}"
	fi

	if [ -n "${NEW_JENKINS_HTTP2_PORT}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --http2Port=${NEW_JENKINS_HTTP2_PORT}"
	fi

	if [ -n "${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --http2ListenAddress=${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}"
	fi

	if [ "${NEW_JENKINS_DEBUG_LEVEL}" != "${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --debug=${NEW_JENKINS_DEBUG_LEVEL}"
	fi

	if [ -n "${NEW_JENKINS_EXTRA_LIB_FOLDER}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --extraLibFolder='${NEW_JENKINS_EXTRA_LIB_FOLDER}'"
	fi

	if [ -n "${NEW_JENKINS_PREFIX}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --prefix='${NEW_JENKINS_PREFIX}'"
	fi

	if [ -n "${NEW_JENKINS_EXTRA_ARGS}" ]; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} ${JENKINS_EXTRA_ARGS}"
	fi

	if $NEW_JENKINS_ENABLE_ACCESS_LOG; then
		NEW_JENKINS_ARGS="${NEW_JENKINS_ARGS} --accessLoggerClassName=winstone.accesslog.SimpleAccessLogger --simpleAccessLogger.format=combined --simpleAccessLogger.file=/var/log/@@ARTIFACTNAME@@/access_log"
	fi
}

get_new_config() {
	# TODO implement this
	echo "The migrated configuration now looks like this:"
	cat <<-EOF
		[Service]
		Type=simple
		User=${NEW_JENKINS_USER}
		Group=${NEW_JENKINS_GROUP}
		Environment="HOME=${NEW_JENKINS_HOME}"
		Environment="JENKINS_HOME=${NEW_JENKINS_HOME}"
		WorkingDirectory=${NEW_JENKINS_HOME}
		ExecStart="${NEW_JENKINS_JAVA_CMD}" ${NEW_JENKINS_JAVA_ARGS} -jar "${NEW_JENKINS_WAR}" ${NEW_JENKINS_ARGS}
		LimitNOFILE=${NEW_JENKINS_MAXOPENFILES}
		Restart=on-failure
		SuccessExitStatus=143
		UMask=${NEW_JENKINS_UMASK}
	EOF
	echo Compare the above to /lib/systemd/system/jenkins.service. If there are any differences, write out only those differences to /etc/systemd/system/jenkins.service.d/override.conf.
}

main() {
	from=$1

	echo "Migrating ${from} ..."
	# TODO skip migration if the migration marker exists

	[ -f "${from}" ] || die "${from} does not exist"
	. "${from}"

	read_old_options
	# TODO add lifecycle to java args if it's missing
	infer_jenkins_args
	get_new_config
	# TODO write out a maker that the migration has been completed
}

[ $# -gt 1 ] && usage "too many arguments specified"
[ $# -lt 1 ] && usage "too few arguments specified"
main "$1"

exit 0

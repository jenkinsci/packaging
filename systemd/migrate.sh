#!/bin/sh

set -e

die() {
	echo "$(basename "$0"): $*" >&2
	exit 2
}

usage() {
	echo "$(basename "$0"): $*" >&2
	echo "Usage: $(basename "$0") <from> <to>"
	exit 2
}

NEW_JAVA_OPTS_DEFAULT="-Dhudson.lifecycle=hudson.lifecycle.ExitLifecycle -Djava.awt.headless=true"
NEW_JENKINS_DEBUG_LEVEL_DEFAULT="5"
NEW_JENKINS_GROUP_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_HOME_DEFAULT="/var/lib/@@ARTIFACTNAME@@"
NEW_JENKINS_LOG_DEFAULT="/var/log/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.log"
NEW_JENKINS_MAXOPENFILES_DEFAULT="8192"
NEW_JENKINS_PORT_DEFAULT="@@PORT@@"
NEW_JENKINS_USER_DEFAULT="@@ARTIFACTNAME@@"
NEW_JENKINS_WAR_DEFAULT="/usr/lib/@@ARTIFACTNAME@@/@@ARTIFACTNAME@@.war"
NEW_JENKINS_WEBROOT_DEFAULT="/var/cache/@@ARTIFACTNAME@@/war"

NEW_JAVA_HOME=""
NEW_JAVA_OPTS="${NEW_JAVA_OPTS_DEFAULT}"
NEW_JENKINS_DEBUG_LEVEL="${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}"
NEW_JENKINS_ENABLE_ACCESS_LOG=false
NEW_JENKINS_EXTRA_LIB_FOLDER=""
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

read_old_options() {
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
	# TODO add lifecycle to java args if it's missing

	if [ -n "${JENKINS_LISTEN_ADDRESS}" ]; then
		NEW_JENKINS_LISTEN_ADDRESS="${JENKINS_LISTEN_ADDRESS}"
	fi

	if [ -n "${HTTP_PORT}" ] && [ "${HTTP_PORT}" -gt 0 ]; then
		NEW_JENKINS_PORT="${HTTP_PORT}"
	elif [ -n "${JENKINS_PORT}" ] && [ "${JENKINS_PORT}" -gt 0 ]; then
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

	if [ -n "${JENKINS_HTTP2_LISTEN_ADDRESS}" ] && [ "${JENKINS_HTTP2_LISTEN_ADDRESS}" -gt 0 ]; then
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

	if [ -n "${JENKINS_EXTRA_LIB_FOLDER}" ] && [ -d "${JENKINS_EXTRA_LIB_FOLDER}" ]; then
		NEW_JENKINS_EXTRA_LIB_FOLDER="${JENKINS_EXTRA_LIB_FOLDER}"
	fi

	if [ -n "${PREFIX}" ]; then
		NEW_JENKINS_PREFIX="${PREFIX}"
	fi

	if [ -n "${JENKINS_ARGS}" ]; then
		if [ -n "${NAME}" ]; then
			# For deb, these are all the arguments, except for the JENKINS_ENABLE_ACCESS_LOG additions
			# TODO parse these out into the rpm/suse style variables, and put the remainder in NEW_JENKINS_OPTS
			# TODO also add -logfile if it's missing
			echo 'implement me'
		else
			# For rpm and suse, these are extra arguments
			NEW_JENKINS_OPTS="${JENKINS_ARGS}"
		fi
	fi

	if [ -n "${MAXOPENFILES}" ] && [ "${MAXOPENFILES}" -gt 0 ]; then
		NEW_JENKINS_MAXOPENFILES="${MAXOPENFILES}"
	fi

	if [ -n "${UMASK}" ]; then
		NEW_JENKINS_UMASK="${UMASK}"
	fi
}

migrate_options() {
	tmpfile=$(mktemp)
	edited=false

	if [ -f /etc/systemd/system/@@ARTIFACTNAME@@.service.d/override.conf ]; then
		return
	fi

	echo '[Service]' >>"${tmpfile}"

	if [ "${NEW_JENKINS_USER}" != "${NEW_JENKINS_USER_DEFAULT}" ]; then
		echo "User=${NEW_JENKINS_USER}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_GROUP}" != "${NEW_JENKINS_GROUP_DEFAULT}" ]; then
		echo "Group=${NEW_JENKINS_GROUP}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_HOME}" != "${NEW_JENKINS_HOME_DEFAULT}" ]; then
		echo "Environment=\"HOME=${NEW_JENKINS_HOME}\"" >>"${tmpfile}"
		echo "Environment=\"JENKINS_HOME=${NEW_JENKINS_HOME}\"" >>"${tmpfile}"
		echo "WorkingDirectory=${NEW_JENKINS_HOME}" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_WAR}" != "${NEW_JENKINS_WAR_DEFAULT}" ]; then
		echo "Environment=\"JENKINS_WAR=${NEW_JENKINS_WAR}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_WEBROOT}" != "${NEW_JENKINS_WEBROOT_DEFAULT}" ]; then
		echo "Environment=\"JENKINS_WEBROOT=${NEW_JENKINS_WEBROOT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_LOG}" != "${NEW_JENKINS_LOG_DEFAULT}" ]; then
		echo "Environment=\"JENKINS_LOG=${NEW_JENKINS_LOG}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JAVA_HOME}" ]; then
		echo "Environment=\"JAVA_HOME=${NEW_JAVA_HOME}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_JAVA_CMD}" ]; then
		echo "Environment=\"JENKINS_JAVA_CMD=${NEW_JENKINS_JAVA_CMD}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JAVA_OPTS}" != "${NEW_JAVA_OPTS_DEFAULT}" ]; then
		echo "Environment=\"JAVA_OPTS=${NEW_JAVA_OPTS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_LISTEN_ADDRESS}" ]; then
		echo "Environment=\"JENKINS_LISTEN_ADDRESS=${NEW_JENKINS_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_PORT}" != "${NEW_JENKINS_PORT_DEFAULT}" ]; then
		echo "Environment=\"JENKINS_PORT=${NEW_JENKINS_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}" ]; then
		echo "Environment=\"JENKINS_HTTPS_LISTEN_ADDRESS=${NEW_JENKINS_HTTPS_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_PORT}" ]; then
		echo "Environment=\"JENKINS_HTTPS_PORT=${NEW_JENKINS_HTTPS_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE}" ]; then
		echo "LoadCredential=keystore.jks:${NEW_JENKINS_HTTPS_KEYSTORE}">> "${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}" ]; then
		echo "SetCredential=keystore.pass:${NEW_JENKINS_HTTPS_KEYSTORE_PASSWORD}" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}" ]; then
		echo "Environment=\"JENKINS_HTTP2_LISTEN_ADDRESS=${NEW_JENKINS_HTTP2_LISTEN_ADDRESS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_HTTP2_PORT}" ]; then
		echo "Environment=\"JENKINS_HTTP2_PORT=${NEW_JENKINS_HTTP2_PORT}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_DEBUG_LEVEL}" != "${NEW_JENKINS_DEBUG_LEVEL_DEFAULT}" ]; then
		echo "Environment=\"JENKINS_DEBUG_LEVEL=${NEW_JENKINS_DEBUG_LEVEL}\"" >>"${tmpfile}"
		edited=true
	fi

	if $NEW_JENKINS_ENABLE_ACCESS_LOG; then
		echo "Environment=\"JENKINS_ENABLE_ACCESS_LOG=${NEW_JENKINS_ENABLE_ACCESS_LOG}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_EXTRA_LIB_FOLDER}" ]; then
		echo "Environment=\"JENKINS_EXTRA_LIB_FOLDER=${NEW_JENKINS_EXTRA_LIB_FOLDER}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_PREFIX}" ]; then
		echo "Environment=\"JENKINS_PREFIX=${NEW_JENKINS_PREFIX}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_OPTS}" ]; then
		echo "Environment=\"JENKINS_OPTS=${NEW_JENKINS_OPTS}\"" >>"${tmpfile}"
		edited=true
	fi

	if [ "${NEW_JENKINS_MAXOPENFILES}" != "${NEW_JENKINS_MAXOPENFILES_DEFAULT}" ]; then
		echo "LimitNOFILE=${NEW_JENKINS_MAXOPENFILES}" >>"${tmpfile}"
		edited=true
	fi

	if [ -n "${NEW_JENKINS_UMASK}" ]; then
		echo "LimitNOFILE=${NEW_JENKINS_MAXOPENFILES}" >>"${tmpfile}"
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

	# TODO skip migration if the migration marker exists
	[ -f "${from}" ] || die "${from} does not exist"
	. "${from}"
	read_old_options
	migrate_options
	# TODO write out a marker that the migration has been completed
}

[ $# -gt 1 ] && usage "too many arguments specified"
[ $# -lt 1 ] && usage "too few arguments specified"
main "$1"

exit 0

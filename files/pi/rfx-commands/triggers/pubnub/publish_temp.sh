#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Variables and funtions...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"
logfile="/var/rfxcmd/pubnub-errors.log"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../../functions.sh
settings=${scriptDir}/../../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

#	Create logfile if needed

[ ! -r ${logfile} ] && umask 0011 && touch ${logfile} && chown pi:pi ${logfile}

sensor_id=${1}
sensor_temp=${2}
sensor_humidity=${3}
sensor_signal=${4}
now_full="$(date '+%F %T')"

# Only allow publish if android app hallonet is running, But allow id 0000

if [ "${sensor_id}" != "0000" ] ; then
	[ ! -r "${PUBNUB_ALLOWPUBLISH}" ] && exit 0
fi


#
#	Use flock to prevent multiple sensors to manipulate sensors.json
#

(
	flock -x -w 30 200 || { logger -t $(basename $0) "Failed to aquire lock for ${sensor_id}"; exit 1; }
	[ ${SECONDS} -gt 0 ] && logger -t $(basename $0) "$$ -> Aquired lock temp ${sensor_id}->${sensor_temp} -> ${SECONDS}"

	#
	#	Send it to pubnub
	#

	log "To PubNub [${sensor_id}] = ${sensor_temp}" >> ${UPDATE_REST_LOG} 2>&1

	{
	${scriptDir}/publish_to_pubnub.py \
		--file            "${JSON_FILE}" \
		--pubnub-subkey   "${PUBNUB_SUBKEY}" \
		--pubnub-pubkey   "${PUBNUB_PUBKEY}" \
		--pubnub-channel  "${PUBNUB_CHANNEL_SENSORS}" \
		--sensor-id       "${sensor_id}" \
		--sensor-value    "${sensor_temp}" \
		--sensor-humidity "${sensor_humidity}" \
		--stamp           "${now_full}" \
		--signal          "${sensor_signal}"
	} > "${tmpfile}" 2>> "${logfile}"

	#
	#	Did we get a proper json back ?, If so upload it, but only if id is 0000
	#

	if [ "${sensor_id}" = "0000" ] ; then

		python -mjson.tool "${tmpfile}" > /dev/null 2>&1; status=$?

		if [ "${status}" -eq 0 ] ; then

			cp ${tmpfile} "${JSON_FILE}"
			to_webroot static ${JSON_FILE}
			to_static ${JSON_FILE}
		fi

	fi
	
	#logger "$$ -> Jobe done temp ${sensor_id}"

) 200> /var/lock/sensor.lock

exit 0

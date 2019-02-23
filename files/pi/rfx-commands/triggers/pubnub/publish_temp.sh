#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${jqfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Variables and funtions...
#
######################################################################

tmpfile="/tmp/$(basename $0)-$$.tmp"
jqfile="/tmp/$(basename $0)-$$.json"

[ -h "$0" ] && scriptDir=$(dirname "$(readlink -m $0)") || scriptDir=$( cd "$(dirname $0)" && pwd)

functions=${scriptDir}/../../functions.sh
settings=${scriptDir}/../../settings.cfg

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || { logger -t "$(basename $0)" "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${functions} ] && source ${functions} || { logger -t "$(basename $0)" "FATAL: Missing '${functions}', Aborting" ; exit 1; }

#	Create logfile if needed

[ ! -r ${PUBNUB_ERROR_LOG} ] && umask 0011 && touch ${PUBNUB_ERROR_LOG} && chown pi:pi ${PUBNUB_ERROR_LOG}

sensor_id=${1}
sensor_value=${2}
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
	flock -x -w 30 200 || { logger -t "$(basename $0)" "Failed to aquire lock for ${sensor_id}"; exit 1; }
	[ ${SECONDS} -gt 1 ] && logger -t "$(basename $0)" "$$ -> Aquired lock temp ${sensor_id}->${sensor_value} -> ${SECONDS}"


	# Update sensors.json with new data

	{
	${scriptDir}/update_json.py \
		--file            "${JSON_FILE}" \
		--sensor-id       "${sensor_id}" \
		--sensor-value    "${sensor_value}" \
		--sensor-humidity "${sensor_humidity}" \
		--stamp           "${now_full}" \
		--signal          "${sensor_signal}"
	} > "${tmpfile}" 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

	if [ ${status} -ne 0 ] ; then
		logger -t "$(basename $0)" "Failed to parse json ${JSON_FILE}"
		exit 1
	fi

	# Extract sensor data

	jq -e --arg sid ${sensor_id} '{type:"sensor", sensor: .sensors | .[] | select(.id==$sid)}' \
		< ${tmpfile} > ${jqfile} 2>> "${PUBNUB_ERROR_LOG}" ; status=$?
	
	if [ ${status} -eq 0 ] ; then
		
		alias=$(jq -e -r '.sensor.alias' < ${jqfile} 2>> "${PUBNUB_ERROR_LOG}")

		# Send it to pubnub
		
		log "To PubNub ${alias} [${sensor_id}] = ${sensor_value}" >> ${UPDATE_REST_LOG} 2>&1

		pn_gw_publish "${PUBNUB_CHANNEL_SENSORS}" "${jqfile}" > /dev/null 2>&1
		
		logger -t "$(basename $0)" "Published ${alias} [${sensor_id}] = ${sensor_value}"
		
		# Upload json only if sensor = 0000

		if [ "${sensor_id}" = "0000" ] ; then
			cp ${tmpfile} "${JSON_FILE}"
			to_webroot static ${JSON_FILE}
			to_static ${JSON_FILE}
		fi
	fi

	#logger "$$ -> Job done temp ${sensor_id}"

) 200> /var/lock/sensor.lock

exit 0

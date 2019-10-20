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

switch_id="${1}"
switch_state="${2}"
switch_signal="${3}"
now_full="$(date '+%F %T')"


#
#	Use flock to prevent multiple sensors to manipulate sensors.json
#

(
	flock -x -w 30 200 || { logger -t "$(basename $0)" "Failed to aquire lock for ${switch_id}"; exit 1; }
	[ ${SECONDS} -gt 1 ] && logger -t "$(basename $0)" "$$ -> Aquired lock switch ${switch_id}->${switch_state} -> ${SECONDS}"


	# Update sensors.json with new data

	{
	${scriptDir}/update_json.py \
		--file           "${JSON_FILE}" \
		--switch-id      "${switch_id}" \
		--switch-state   "${switch_state}" \
		--stamp          "${now_full}" \
		--signal         "${switch_signal}"
	} > "${tmpfile}" 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

	if [ ${status} -ne 0 ] ; then
		logger -t "$(basename $0)" "Failed to parse json ${JSON_FILE}"
		exit 1
	fi

	# Extract sensor data

	jq -e --arg sid ${switch_id} '{type:"switch", switch: .switches | .[] | select(.id==$sid)}' \
		< ${tmpfile} > ${jqfile} 2>> "${PUBNUB_ERROR_LOG}" ; status=$?
	
	if [ ${status} -eq 0 ] ; then
		
		switch_alias=$(jq -e -r '.switch.alias' < ${jqfile} 2>> "${PUBNUB_ERROR_LOG}")
		switch_type=$(jq -e -r '.switch.type' < ${jqfile} 2>> "${PUBNUB_ERROR_LOG}")
		
		if [ "${switch_type}" = "magnet" ] ; then
		    switch_type=$(jq -e -r '.switch.subtype' < ${jqfile} 2>> "${PUBNUB_ERROR_LOG}")
		fi

		verbose=$(command_verbose "${switch_state}" "${switch_type}")


		# Send it to pubnub
		
		#log "To PubNub ${switch_alias} [${switch_id}] = ${switch_state}" >> ${UPDATE_REST_LOG} 2>&1
		log "To PubNub ${switch_alias} (${switch_type}) = ${verbose} [${switch_id}:${switch_state}]" >> ${UPDATE_REST_LOG} 2>&1

		pn_gw_publish "${PUBNUB_CHANNEL_SENSORS}" "${jqfile}" > /dev/null 2>&1
		
		logger -t "$(basename $0)" "Published ${switch_alias} (${switch_type}) = ${verbose} [${switch_id}:${switch_state}]"
		
		cp ${tmpfile} "${JSON_FILE}"
		to_webroot static ${JSON_FILE}
		to_static ${JSON_FILE}
	fi

	#logger "$$ -> Job done switch ${switch_id}"

) 200> /var/lock/sensor.lock

exit 0

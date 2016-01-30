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

switch_id="${1}"
switch_state="${2}"
switch_signal="${3}"

now_full="$(date '+%F %T')"


#
#	Use flock to prevent multiple triggers to manipulate sensors.json
#

(
	flock -x -w 30 200 || { logger -t $(basename $0) "Failed to aquire lock for ${switch_id}"; exit 1; }
	[ ${SECONDS} -gt 0 ] && logger -t $(basename $0) "$$ -> Aquired lock switch ${switch_id}->${switch_state} -> ${SECONDS}"

	#
	# 	Always publish switches even if android app hallonet is not running
	#

	{
	${scriptDir}/publish_to_pubnub.py \
		--file           "${JSON_FILE}" \
		--pubnub-subkey  "${PUBNUB_SUBKEY}" \
		--pubnub-pubkey  "${PUBNUB_PUBKEY}" \
		--pubnub-channel "${PUBNUB_CHANNEL_SENSORS}" \
		--switch-id      "${switch_id}" \
		--switch-state   "${switch_state}" \
		--stamp          "${now_full}" \
		--signal         "${switch_signal}"
	} > "${tmpfile}" 2>> "${logfile}"

	#
	#	Did we get a proper json back ?, If so upload it
	#

	python -mjson.tool "${tmpfile}" > /dev/null 2>&1; status=$?

	if [ "${status}" -eq 0 ] ; then

		cp ${tmpfile} "${JSON_FILE}"
		to_webroot static ${JSON_FILE}
		to_static ${JSON_FILE}
	fi 

	#logger "$$ -> Job done switch ${switch_id}->${switch_state}"

) 200> /var/lock/sensor.lock

exit 0

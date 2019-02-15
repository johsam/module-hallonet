#!/bin/bash


######################################################################
#
#	To be used from cron or prompt...
#	usage: script <1-4> on|off or script group off|group off
#
######################################################################


######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"
logfile="/var/rfxcmd/nexa-setstate.log"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg
sensors=${scriptDir}/../sensors.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${sensors} ]   && source ${sensors}   || { logger -t $(basename $0) "FATAL: Missing '${sensors}', Aborting" ; exit 1; }

light_id="$(echo "${1}" | tr '[:lower:]' '[:upper:]')"
light_command="${2^}"

if [ "${light_id}" = "GROUP OFF" ] ; then
	${0} 1 Off
	sleep 1
	${0} 2 Off
	exit 0
fi

if [ "${light_id}" = "GROUP ON" ] ; then
	${0} 1 On
	sleep 1
	${0} 2 On
	exit 0
fi


#
#	Use flock to prevent multiple cron jobs to send at the same time
#


(
	flock -x -w 30 200 || { logger -t "$(basename $0)" "Failed to aquire lock for ${light_id}->${light_command}"; exit 1; }
	[ ${SECONDS} -gt 1 ] && logger -t "$(basename $0)" "$$ -> Aquired lock nexa ${light_id}->${light_command} -> ${SECONDS}"


    	logger -t "$(basename $0)" "$$ -> Aquired lock nexa ${light_id}->${light_command}"

	#
	#	Get current state
	#

	last_state=$(${scriptDir}/../scripts/nexa-get-state.sh ${light_id})

	#
	#	Only send if state differs
	#

	if [ "${light_command}" != "${last_state^}" ] ; then
		${scriptDir}/../triggers/lights.sh "${remote_nexa}" "${light_command}" "${light_id}"
	else
		log "ignore (${light_id} -> ${light_command})" >> "${logfile}"
		logger -t $(basename $0) "Skip nexa ${light_id} -> ${light_command}, State was already ${last_state^}"

	fi

    	logger -t "$(basename $0)" "$$ -> Released lock nexa ${light_id}->${light_command}"

) 200> /var/lock/nexa.lock


exit 0

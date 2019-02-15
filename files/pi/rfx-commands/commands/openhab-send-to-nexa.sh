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
#	Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

influxtime="$(date +%s)000000000"

tmpfile="/tmp/`basename $0`-$$.tmp"

settings=${scriptDir}/../settings.cfg
functions=${scriptDir}/../functions.sh
sensors="${scriptDir}/../sensors.cfg"

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${sensors} ]   && source ${sensors}   || { logger -t $(basename $0) "FATAL: Missing '${sensors}', Aborting" ; exit 1; }


# Do it

ipaddress=127.0.0.1

switch_id=${1}
sw_command="$(echo "${2}" | tr '[:upper:]' '[:lower:]')"
switch_command=${sw_command^}

log "send  (${switch_id} -> ${switch_command})" >> /var/rfxcmd/nexa-setstate.log

if [ ${switch_command} == "On" ] ; then
	/opt/rfxcmd/rfxsend.py -s ${ipaddress} -r "0B110000${remote_nexa}0${switch_id}010F00"
else
	/opt/rfxcmd/rfxsend.py -s ${ipaddress} -r "0B110000${remote_nexa}0${switch_id}000000"
fi

#	Sent to pubnub

${scriptDir}/../triggers/pubnub/publish_switch.sh "${remote_nexa}_${switch_id}" "${switch_command}" "0"

#	Send it to influxdb

light_to_influxdb "${remote_nexa}_${switch_id}" "${switch_command}" "${influxtime}" >> ${UPDATE_REST_LOG}

#   	Send it to home-assistant

${scriptDir}/../triggers/hass/send_state.sh "${switch_id}" "${sw_command}"

exit 0

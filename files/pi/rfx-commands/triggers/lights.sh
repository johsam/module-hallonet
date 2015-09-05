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

tmpfile="/tmp/`basename $0`-$$.tmp"
logfile="/var/rfxcmd/nexa-setstate.log"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)
[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)


light_id=${1}
light_command=${2}
light_unitcode=${3}


# Do it

umask 0011

log "trigger (${light_unitcode} -> ${light_command})" >> "${logfile}"


onOff="$(echo "${light_command}" | tr '[:lower:]' '[:upper:]')"


if [ "${onOff}" = "GROUP OFF" ] ; then
	${0} ${id} Off 1
	sleep 1
	${0} ${id} Off 2
	exit 0
fi

if [ "${onOff}" = "GROUP ON" ] ; then
	${0} ${id} On 1
	sleep 1
	${0} ${id} On 2
	exit 0
fi

#	Send it to openhab

to_openhab "Light trigger" "Nexa_${light_unitcode}" "${onOff}" >> ${UPDATE_REST_LOG}

#	Send it to pubnub

${scriptDir}/pubnub/publish_switch.sh "${id}_${light_unitcode}" "${light_command}"


exit 0

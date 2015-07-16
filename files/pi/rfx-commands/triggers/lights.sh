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


# Do it

umask 0011

log "trigger ($1 -> $2)" >> "${logfile}"


id=$1
onOff="$(echo "$2" | tr '[:lower:]' '[:upper:]')"


if [ "${onOff}" = "GROUP OFF" ] ; then
	${0} 1 off
	sleep 1
	${0} 2 off
	exit 0
fi

if [ "${onOff}" = "GROUP ON" ] ; then
	${0} 1 on
	sleep 1
	${0} 2 on
	exit 0
fi

#	Send it 

to_openhab "Light trigger" "Nexa_${id}" "${onOff}" >> ${UPDATE_REST_LOG}

exit 0

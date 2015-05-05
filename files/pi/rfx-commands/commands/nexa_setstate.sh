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

[ -h "$0" ] && dir=$(dirname `readlink $0`) || dir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"

settings=${dir}/../settings.cfg
functions=${dir}/../functions.sh

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)
[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)


# Do it

umask 0011

log "state ($1 -> $2)" >> /var/rfxcmd/nexa-setstate.log


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


/usr/bin/curl -s --header 'Content-Type: text/plain' --request POST --data "${onOff}" http://localhost:8080/rest/items/Nexa_${id}


exit 0

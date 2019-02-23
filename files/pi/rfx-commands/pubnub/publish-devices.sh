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

tmpfile="/tmp/$(basename $0)-$$.tmp"
forceSend=0

[ -h "$0" ] && scriptDir=$(dirname "$(readlink -m $0)") || scriptDir=$( cd "$(dirname $0)" && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg


# Sanity checks

[ -r ${settings} ]  && source ${settings}  || { logger -t "$(basename $0)" "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${functions} ] && source ${functions} || { logger -t "$(basename $0)" "FATAL: Missing '${functions}', Aborting" ; exit 1; }

# Any parameters ?

while getopts "f" _opts
do
	case "${_opts}" in
	f) forceSend=1;;
	?) exit 1 ;;
	esac
done

shift $(( OPTIND - 1 )) ; OPTIND=1
[ "$1" = "--" ] && shift


# Don't publish if we have no listeners, But allow a force (-f)

if [ ${forceSend} -ne 0 ] || [ -r "${PUBNUB_ALLOWPUBLISH}" ] ; then
	
	logger -t "$(basename $0)" "Sending devices '${WIDGET_DEV_1},${WIDGET_DEV_2},${WIDGET_DEV_3}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
	
	jq -e --arg d1 ${WIDGET_DEV_1} --arg d2 ${WIDGET_DEV_2} --arg d3 ${WIDGET_DEV_3} \
	    '{type:"devices", devices: [.devices | .[] | select(.id==($d1,$d2,$d3))]}' \
	< ${JSON_FILE} > ${tmpfile} 2>> "${PUBNUB_ERROR_LOG}"
	
	pn_gw_publish "${PUBNUB_CHANNEL_SENSORS}" "${tmpfile}" > /dev/null 2>&1

else 
	logger "Should send '${1}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
fi


exit 0
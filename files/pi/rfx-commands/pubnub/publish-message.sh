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
notify=0

[ -h "$0" ] && scriptDir=$(dirname "$(readlink -m $0)") || scriptDir=$( cd "$(dirname $0)" && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || { logger -t "$(basename $0)" "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${functions} ] && source ${functions} || { logger -t "$(basename $0)" "FATAL: Missing '${functions}', Aborting" ; exit 1; }

# Any parameters ?

while getopts "fn" _opts
do
	case "${_opts}" in
	f) forceSend=1;;
	n) notify=1;;
	?) exit 1 ;;
	esac
done

shift $(( OPTIND - 1 )) ; OPTIND=1
[ "$1" = "--" ] && shift


# Don't publish if we have no listeners, But allow a force (-f)

if [ ${forceSend} -ne 0 ] || [ -r "${PUBNUB_ALLOWPUBLISH}" ] ; then
	
	logger "Sending '${1}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
	
	if [ ${notify} -eq 0 ] ; then
	 	pn_gw_message "${1}"
	else 
		pn_gw_notice "${1}"
	fi

else 
	logger "Should send '${1}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
fi


exit 0
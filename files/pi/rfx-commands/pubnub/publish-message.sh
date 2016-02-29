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
forceSend=0

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg



# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

# Any parameters ?

while getopts "f" _opts
do
	case "${_opts}" in
	f) forceSend=1;;
	?) exit 1 ;;
	esac
done

shift `expr $OPTIND - 1` ; OPTIND=1
[ "$1" = "--" ] && shift


# Don't publish if we have no listeners, But allow a force (-f)

if [ ${forceSend} -ne 0 ] || [ -r "${PUBNUB_ALLOWPUBLISH}" ] ; then
	
	logger "Sending '${1}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
	
	${scriptDir}/../triggers/pubnub/publish_to_pubnub.py \
		--file 		  /dev/null \
		--pubnub-subkey   "${PUBNUB_SUBKEY}" \
		--pubnub-pubkey   "${PUBNUB_PUBKEY}" \
		--pubnub-channel  "${PUBNUB_CHANNEL_SENSORS}" \
		--message         "${1}"
else 
	logger "Should send '${1}' to channel '${PUBNUB_CHANNEL_SENSORS}'"
fi


exit 0

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

[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)
[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)

#	Create logfile if needed

[ ! -r ${logfile} ] && umask 0011 && touch ${logfile} && chown pi:pi ${logfile}

sensor_id=${1}
sensor_temp=${2}
sensor_humidity=${3}
now_full="$(date '+%F %T')"

# Only allow publish if android app hallonet is running, But allow id 0000

if [ "${sensor_id}" != "0000" ] ; then
	[ ! -r "${PUBNUB_ALLOWPUBLISH}" ] && exit 0
fi

#
#	Send it to pubnub
#

{
${scriptDir}/publish_to_pubnub.py \
	--file            "${JSON_FILE}" \
	--pubnub-subkey   "${PUBNUB_SUBKEY}" \
	--pubnub-pubkey   "${PUBNUB_PUBKEY}" \
	--pubnub-channel  "${PUBNUB_CHANNEL}" \
	--sensor-id       "${sensor_id}" \
	--sensor-value    "${sensor_temp}" \
	--sensor-humidity "${sensor_humidity}" \
	--stamp           "${now_full}"
} > "${tmpfile}" 2>> "${logfile}"

#
#	Did we get a proper json back ?, If so upload it, but only if id is 0000
#

if [ "${sensor_id}" = "0000" ] ; then

	python -mjson.tool "${tmpfile}" > /dev/null 2>&1; status=$?
 
	if [ "${status}" -eq 0 ] ; then
		cp ${tmpfile} "${JSON_FILE}"
		upload_static static ${JSON_FILE}
	fi

fi

exit 0

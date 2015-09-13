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

ipaddress=127.0.0.1

log "send  (${1} -> on)" >> /var/rfxcmd/nexa-setstate.log

/opt/rfxcmd/rfxsend.py -s ${ipaddress} -r "0B11000000D813320${1}010F00"

#	Sent to pubnub

${dir}/../triggers/pubnub/publish_switch.sh "00D81332_${1}" "On" "0"


exit 0

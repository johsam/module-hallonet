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

if [ -n "${MAILTO}" ] ; then
	log "Sending mail to '${MAILTO}'"
	/usr/bin/mailx -s "${1}" ${MAILTO} < /dev/null
fi

exit 0

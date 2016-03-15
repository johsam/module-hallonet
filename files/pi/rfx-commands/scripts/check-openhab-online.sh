#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${restartfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"
restartfile="/tmp/restart-openhab.run"

#-------------------------------------------------------------------------------
#
#	Function reportStatus: message
#
#-------------------------------------------------------------------------------

function reportStatus ()
{
printf "$(date '+%F %T') ${1}\n"
exit 0
}


#-------------------------------------------------------------------------------
#
#	Main
#
#-------------------------------------------------------------------------------


[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }


/bin/ping -c 2 -I wlan0 my.openhab.org > /dev/null 2> /dev/null ; status=$?

if [ ${status} -ne 0 ] ; then
	reportStatus "unpingable"
fi

#
#	Curl it...
#

(
/usr/bin/curl \
	--silent \
	--connect-timeout 15 \
	--max-time        30 \
	--user            ${MY_OPENHAB_USER} \
	--url             "https://my.openhab.org/openhab.app?sitemap=ripan#_Home"
  
) > "${tmpfile}" ; status=$?

if [ ${status} -eq 0 ] ; then

	grep -q -i "is offline"  "${tmpfile}" ; status=$?

	if [ ${status} -eq 0 ] ; then
		
		#
		#	Upload a file to force a restart of openhab the next time update-openhab.sh runs
		#
		
		touch "${restartfile}"
		to_webroot static ${restartfile}

		
		reportStatus "offline"
	else
		reportStatus "ok"
	fi
else
	
	reportStatus "timeout"
fi



exit 0

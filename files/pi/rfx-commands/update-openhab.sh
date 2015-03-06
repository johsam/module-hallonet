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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
counterfile="/var/rfxcmd/update-openhab.counter"

#-------------------------------------------------------------------------------
#
#	Function log
#
#-------------------------------------------------------------------------------

function log ()
{
printf "%s %s\n" "$(date '+%F %T')" "${1}"
}



(

#
#	Increment counter file...
#

[ ! -r "${counterfile}" ] && echo "0" > "${counterfile}"

perl -i -pe 's/(\d+)/$1 + 1/e' "${counterfile}"


log "Starting job..."

${scriptDir}/static/doit.sh



#
#	Check if we should run something every n:th time
#

runCounter="$(cat ${counterfile})"
hour="$(date +%H)"

log "Counter is [${runCounter}]"

#	JSON files to bbb

if [[ $(( ${runCounter} % 3)) -eq 0 ]] ; then
	log "Counter % 3 -> Updating json 24 hours"
	${scriptDir}/static/4_tnu-to-json-to-bbb.sh
fi


if [[ $(( ${runCounter} % 6)) -eq 0 ]] ; then
	log "Counter % 6 -> Updating json 72 hours"
	${scriptDir}/static/4_tnu-to-json-to-bbb.sh -l
fi

if [[ $(( ${runCounter} % 36)) -eq 0 ]] ; then
	log "Counter % 36 -> Updating json 168 hours"
	${scriptDir}/static/4_tnu-to-json-to-bbb.sh -w
fi


#	Graphs

if [ ${hour} -gt 6 ] ; then

	if [[ $(( ${runCounter} % 2)) -eq 0 ]] ; then
		log "Counter % 2 -> Updating graph"
		sudo ${scriptDir}/scripts/update-graphs.sh -1
	fi

	if [[ $(( ${runCounter} % 6)) -eq 0 ]] ; then
		log "Counter % 6 -> Updating graph -2"
		sudo ${scriptDir}/scripts/update-graphs.sh -2
	fi

	if [[ $(( ${runCounter} % 21)) -eq 0 ]] ; then
		log "Counter % 21 -> Updating graph -3"
		sudo ${scriptDir}/scripts/update-graphs.sh -3
	fi

else
	log "Counter skipping graph(s) at night..."
fi

#
#	Restart openhab end remove run file from ftp if flag file found
#

log "Check for openhab restart..."
lftp -c "open -u surjohan,yadast ftp.bredband.net; cd static ;find restart-openhab.run" > /dev/null 2>&1; status=$?


if [ ${status} -eq 0 ] ; then
	log "Restarting openhab..."
	lftp -c "open -u surjohan,yadast ftp.bredband.net; rm static/restart-openhab.run" > /dev/null 2>&1; status=$?
	sudo service openhab restart
	log "restarted" >> /var/rfxcmd/openhab-status.log
fi



log "Done..."

) >> /var/rfxcmd/update-rest.log 2>&1

exit 0

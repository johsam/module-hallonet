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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/functions.sh
settings=${scriptDir}/settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

#
#	Start work
#

(

hour="$(date +%H)"
runCounter=$(( ($(date +%_H) * 6)  + ($(date +%_M) / 10) ))

log "Starting job, Counter is [${runCounter}]"

call ${scriptDir}/static/collect.sh -c ${runCounter}


#
#	Check if we should run something every n:th time
#

#	JSON files to bbb


log "Counter % 1 -> Updating json graph for today"
call ${scriptDir}/static/4_hallonet_json.sh -t



if [[ $(( ${runCounter} % 3)) -eq 0 ]] ; then
	log "Counter % 3 -> Updating json graph for 24 hours"
	call ${scriptDir}/static/4_hallonet_json.sh
fi


if [[ $(( ${runCounter} % 6)) -eq 0 ]] ; then
	log "Counter % 6 -> Updating json graph for 72 hours"
	call "${scriptDir}/static/4_hallonet_json.sh" "-l"
	fi

if [[ $(( ${runCounter} % 36)) -eq 0 ]] ; then
	log "Counter % 36 -> Updating json grap for 168 hours"
	call "${scriptDir}/static/4_hallonet_json.sh" "-w"
fi


#	Graphs

if [ ${hour} -ge 6 ] ; then

	if [[ $(( ${runCounter} % 2)) -eq 0 ]] ; then
		log "Counter % 2 -> Updating graph"
		call "${scriptDir}/scripts/update-graphs.sh" "-1"
	fi

	if [[ $(( ${runCounter} % 6)) -eq 0 ]] ; then
		log "Counter % 6 -> Updating graph -2"
		call "${scriptDir}/scripts/update-graphs.sh" "-2"
	
		log "Counter % 6 -> Updating signal-history"
		call -a /dev/null ${scriptDir}/signal/signal.sh -t 40 -d 3

	fi

	if [[ $(( ${runCounter} % 21)) -eq 0 ]] ; then
		log "Counter % 21 -> Updating graph -3"
		call "${scriptDir}/scripts/update-graphs.sh" "-3"
	fi

else
	log "Counter skipping graph(s) at night..."
fi



#
#	Restart openhab end remove run file from ftp if flag file found
#

log "Check for openhab restart..."

find_static static restart-openhab.run ; status=$?

if [ ${status} -eq 0 ] ; then
	log "Restarting openhab..."
	rm_static static/restart-openhab.run ; status=$?
	sudo service openhab restart
	log "restarted" >> /var/rfxcmd/openhab-status.log
fi



log "Done..."

) >> ${UPDATE_REST_LOG} 2>&1

exit 0

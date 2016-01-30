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
logfile="/var/rfxcmd/door-magnet.log"
shortnow=$(date "+%d/%m %T" | sed -e 's/\/0/\//g')

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }


#	Create logfile if needed

umask 022

[ ! -r ${logfile} ] && touch ${logfile} && chown pi:pi ${logfile}

#
# Parameters
#

magnet_id=${1}
magnet_command=${2}
magnet_dimlevel=${3}
magnet_unitcode=${4}
magnet_signal=${5}

# Log parameters to file

msg=$(printf "${magnet_id}\t${magnet_command}\t${magnet_dimlevel}\t${magnet_signal}")
plainlog "${msg}" >> ${logfile}


#	Send it to openhab

magnet_status="Stängd ${shortnow}" ; [ "${magnet_command}" = "On" ] && magnet_status="Öppen ${shortnow}"	

to_openhab "M_${magnet_id}_${magnet_unitcode}" "${magnet_status}" >> ${UPDATE_REST_LOG}


#	Send it to graphite

to_graphite "${magnet_id}_${magnet_unitcode}" "${magnet_command}" >> ${UPDATE_REST_LOG}


#	Send it to pubnub

call "${scriptDir}/pubnub/publish_switch.sh" "${magnet_id}_${magnet_unitcode} ${magnet_command} ${magnet_signal}" >> ${UPDATE_REST_LOG}

exit 0

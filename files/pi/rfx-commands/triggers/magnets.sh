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

[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)
[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)


#	Create logfile if needed

umask 022

[ ! -r ${logfile} ] && touch ${logfile} && chown pi:pi ${logfile}


# Log parameters to file

msg=$(printf "$1\t$2\t$3")
log "${msg}" >> ${logfile}

#	Update openhab

status="Stängd ${shortnow}" ; [ "${2}" = "On" ] && status="Öppen ${shortnow}"	


#	Send it 

to_openhab "Magnet trigger" "M_${1}_${4}" "${status}" >> ${UPDATE_REST_LOG}

exit 0

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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

umask 0011


#logger -t "$(basename $0)" "$$ Call start $1_$4:$2"

#
#   Let's work
#

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg
sensors=${scriptDir}/../sensors.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${sensors} ]   && source ${sensors}   || { logger -t $(basename $0) "FATAL: Missing '${sensors}', Aborting" ; exit 1; }


magnet_id=${1}
magnet_command=${2}
magnet_dimlevel=${3}
magnet_unitcode=${4}
magnet_signal=${5}
magnet_type=${swtype[${magnet_id}_${magnet_unitcode}]:='door'}

id_id="ID_${magnet_id}_${magnet_unitcode}"

magnet_alias="$(echo ${!id_id} | iconv -f ISO-8859-15 -t UTF-8)"
magnet_verbose=$(command_verbose "${magnet_command}" "${magnet_type}")

#
#   Debounce, i.e If we're called with the same parameters, Just exit...
#

(
flock -x -w 30 200 || { logger -t "$(basename $0)" "Failed to aquire lock for ${magnet_id}"; exit 1; }

debounceFile="/tmp/debounce-${magnet_id}_${magnet_unitcode}.tmp"

if [ -s "${debounceFile}" ] ; then

    last=$(cat "${debounceFile}")

    if [ "${magnet_command}" = "${last}" ] ; then
	logger -t "$(basename $0)" "$$ Debounced ${magnet_alias} (${magnet_type}) = ${magnet_verbose} [${magnet_id}_${magnet_unitcode}:${magnet_command}]"
	exit 1
    fi
fi

echo "${magnet_command}" > "${debounceFile}"

) 200> /var/lock/magnet-trigger.lock ; status=$?


if [ ${status} -ne 0 ] ; then
    #logger -t "$(basename $0)" "$$ Call early exit"
    exit 0
fi


#
#   Debounce done. Go ahead and publish
#


influxtime="$(date +%s)000000000"
shortnow=$(date +"%T")


#	Create logfile if needed

[ ! -r ${logfile} ] && touch ${logfile} && chown pi:pi ${logfile}

#
# Parameters
#


# Log parameters to file

msg=$(printf "${magnet_id}\t${magnet_command}\t${magnet_dimlevel}\t${magnet_signal}\t${magnet_type}\t${magnet_alias}")
plainlog "${msg}" >> ${logfile}

#	Send it to influxdb

sw_to_influxdb "${magnet_id}_${magnet_unitcode}" "${magnet_command}" "${influxtime}" >> ${UPDATE_REST_LOG}

#	Send it to pubnub

#logger -t "$(basename $0)" "$$ Call publish_switch.sh"
call "${scriptDir}/pubnub/publish_switch.sh" "${magnet_id}_${magnet_unitcode} ${magnet_command} ${magnet_signal}" >> ${UPDATE_REST_LOG}


#	Send it to openhab

to_openhab "M_${magnet_id}_${magnet_unitcode}" "${magnet_verbose} ${shortnow}" >> ${UPDATE_REST_LOG}

#logger -t "$(basename $0)" "$$ Call exit"

exit 0

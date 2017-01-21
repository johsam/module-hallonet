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

influxtime="$(date +%s)000000000"

tmpfile="/tmp/`basename $0`-$$.tmp"
logfile="/var/rfxcmd/door-magnet.log"
shortnow=$(date "+%d/%m %T" | sed -e 's/\/0/\//g')
debounceFile="/tmp/debounce-switch.tmp"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

umask 0011

#
#   Debounce, i.e If we're called with the same parameters, Just exit...
#

debounced="${1}->${2}"

if [ -s "${debounceFile}" ] ; then

    last=$(cat "${debounceFile}")
    
    if [ "${debounced}" = "${last}" ] ; then
	logger -t "$(basename $0)" "Debounced parameters '$@'"
	exit 0
    fi
fi

echo "${debounced}" > "${debounceFile}"


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


#	Create logfile if needed

[ ! -r ${logfile} ] && touch ${logfile} && chown pi:pi ${logfile}

#
# Parameters
#

magnet_id=${1}
magnet_command=${2}
magnet_dimlevel=${3}
magnet_unitcode=${4}
magnet_signal=${5}
magnet_type=${swtype[${magnet_id}_${magnet_unitcode}]:='door'}

id_id="ID_${magnet_id}_${magnet_unitcode}"
magnet_alias="$(echo ${!id_id} | iconv -f ISO-8859-15 -t UTF-8)"

# Log parameters to file

msg=$(printf "${magnet_id}\t${magnet_command}\t${magnet_dimlevel}\t${magnet_signal}\t${magnet_type}\t${magnet_alias}")
plainlog "${msg}" >> ${logfile}

#	Send it to influxdb

sw_to_influxdb "${magnet_id}_${magnet_unitcode}" "${magnet_command}" "${influxtime}" >> ${UPDATE_REST_LOG}

#	Send it to pubnub

call "${scriptDir}/pubnub/publish_switch.sh" "${magnet_id}_${magnet_unitcode} ${magnet_command} ${magnet_signal}" >> ${UPDATE_REST_LOG}


#	Send it to openhab

if [ "${magnet_command}" = "On" ] ; then
    if [ "${magnet_type}" == "ir" ] ; then
    	utf8_str="Aktiv"
    else
    	utf8_str=$(echo "Öppen" | iconv -f ISO-8859-15 -t UTF-8)
    fi
else
    if [ "${magnet_type}" == "ir" ] ; then
    	utf8_str="Passiv"
    else
    	utf8_str=$(echo "Stängd" | iconv -f ISO-8859-15 -t UTF-8)
    fi
fi

magnet_status="${utf8_str} ${shortnow}"

to_openhab "M_${magnet_id}_${magnet_unitcode}" "${magnet_status}" >> ${UPDATE_REST_LOG}


exit 0

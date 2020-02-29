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


#echo "sensors.temperatures.$1 $2 $(date +%s)" | nc -q0 mint-black 2003

#now="$(date +%s)"

sensor="${1}"
value="${2}"
humidity="${3}"
signal="${4}"
now="${5}"
now="${now:=$(date +%s)}"


#	Get sensor variables and settings

source "${scriptDir}/../sensors.cfg"
source "${scriptDir}/../settings.cfg"
source "${scriptDir}/../functions.sh"

#
#	Convert to arrays
#

outdoor=(${sensors_outdoor//,/ })
indoor=(${sensors_indoor//,/ })
tnu=(${sensors_tnu//,/ })
hum=(${sensors_humidity//,/ })


#-------------------------------------------------------------------------------
#
#	Function containsElement
#
#-------------------------------------------------------------------------------
 
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

#       We want all output appended to the log..

#exec >> ${UPDATE_REST_LOG} 2>&1 


# Handle temp part

sensor_location="unknown"
sensor_type="temperatures"
sensor_tnu="false"

containsElement "${sensor}" "${outdoor[@]}" && sensor_location="outdoor"
containsElement "${sensor}" "${indoor[@]}" && sensor_location="indoor"
containsElement "${sensor}" "${tnu[@]}" && sensor_tnu="true"

# Any aliases ? , Space needs to be escaped, convert to utf-8

alias=${aliases[${sensor}]:='unknown'}
alias=$(echo ${alias// /\\ } | iconv -f ISO-8859-15 -t UTF-8)

# Special cases for 0000 => temperatur.nu 0001 => Median outside

if [ "${sensor}" = "0000" ] || [ "${sensor}" = "0001" ]; then 
	sensor_location="artificial"
fi

# Is it an humidity sensor ?

containsElement "${sensor}" "${hum[@]}" ; status=$?

if [ ${status} -eq 0 ] ; then
    curl -s -XPOST "http://${INFLUXDB_HOST}:8086/write?db=${INFLUXDB_DB}&precision=s" --data-binary "sensors,location=${sensor_location},id=${sensor},alias=${alias},tnu=${sensor_tnu} signal=${signal}i,temp=${value},humidity=${humidity}i ${now}"
else
    curl -s -XPOST "http://${INFLUXDB_HOST}:8086/write?db=${INFLUXDB_DB}&precision=s" --data-binary "sensors,location=${sensor_location},id=${sensor},alias=${alias},tnu=${sensor_tnu} signal=${signal}i,temp=${value} ${now}"
fi

exit 0

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


#echo "sensors.temperatures.$1 $2 $(date +%s)" | nc -q0 mint-black 2003


sensor="${1}"
value="${2}"
humidity="${3}"
host=$(hostname)
now="$(date +%s)"

#	Get sensor variables

source "${dir}/../sensors.cfg"

#
#	Convert to arrays
#

outdoor=(${sensors_outdoor//,/ })
indoor=(${sensors_indoor//,/ })
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


# Handle temp part

sensor_location="unknown"
sensor_type="temperatures"

containsElement "${sensor}" "${outdoor[@]}" && sensor_location="outdoor"
containsElement "${sensor}" "${indoor[@]}" && sensor_location="indoor"

# Special case for 0000 , temperatur.nu 

if [ "${sensor}" = "0000" ] ; then 
	sensor_location="artificial"
fi

path="linux.${host}.sensors.${sensor_location}.${sensor_type}.${sensor} ${value} ${now}"
echo $path | nc -q0 mint-black 2003


# Is it an humidity sensor ?

containsElement "${sensor}" "${hum[@]}" ; status=$?

if [ ${status} -eq 0 ] ; then
	sensor_type="humidity"
	path="linux.${host}.sensors.${sensor_location}.${sensor_type}.${sensor} ${humidity} ${now}"
	echo $path | nc -q0 mint-black 2003
fi

exit 0

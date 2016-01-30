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

sensor="${1}"
value="${2}"
humidity="${3}"
signal="${4}"

host=$(hostname)
now="$(date +%s)"

#	Get sensor variables and settings

source "${scriptDir}/../sensors.cfg"
source "${scriptDir}/../settings.cfg"
source "${scriptDir}/../functions.sh"

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

#       We want all output appended to the log..

exec >> ${UPDATE_REST_LOG} 2>&1 


# Handle temp part

sensor_location="unknown"
sensor_type="temperatures"

containsElement "${sensor}" "${outdoor[@]}" && sensor_location="outdoor"
containsElement "${sensor}" "${indoor[@]}" && sensor_location="indoor"

# Special cases for 0000 => temperatur.nu 0001 => Median outside

if [ "${sensor}" = "0000" ] || [ "${sensor}" = "0001" ]; then 
	sensor_location="artificial"
fi

path="linux.${host}.sensors.${sensor_location}.${sensor_type}.${sensor} ${value} ${now}"
echo $path | nc -q0 mint-black 2003

path="linux.${host}.sensors.${sensor_location}.signal.${sensor} ${signal} ${now}"
echo $path | nc -q0 mint-black 2003



# Is it an humidity sensor ?

containsElement "${sensor}" "${hum[@]}" ; status=$?

if [ ${status} -eq 0 ] ; then
	sensor_type="humidity"
	path="linux.${host}.sensors.${sensor_location}.${sensor_type}.${sensor} ${humidity} ${now}"
	echo $path | nc -q0 mint-black 2003

	${scriptDir}/../triggers/pubnub/publish_temp.sh "${sensor}" "${value}" "${humidity}" "${signal}"
	
	# Update dewpoint
	
	sensor_type="dewpoint"
	dewpoint=$(${scriptDir}/calc_dewpoint.sh "${value}" "${humidity}")
	
	path="linux.${host}.sensors.${sensor_location}.${sensor_type}.${sensor} ${dewpoint} ${now}"
	echo $path | nc -q0 mint-black 2003

else
	${scriptDir}/../triggers/pubnub/publish_temp.sh "${sensor}" "${value}" "${humidity}" "${signal}"
fi


exit 0

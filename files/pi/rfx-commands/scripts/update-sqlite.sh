#!/bin/bash
#echo "sensors.temperatures.$1 $2 $(date +%s)" | nc -q0 mint-black 2003


sensor="${1}"
value="${2}"
humidity="${3}"
host=$(hostname)
now="$(date +%s)"
 
containsElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}


source /home/pi/rfx-commands/sensors.cfg

#
#	Convert to arrays
#

outdoor=(${sensors_outdoor//,/ })
indoor=(${sensors_indoor//,/ })
hum=(${sensors_humidity//,/ })

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






#
#	echo -e "\u2193"
#

now=$(date +%s)
sensorid=$1
value=$2

db="/var/rfxcmd/sqlite.db"


/usr/bin/sqlite3 "${db}" <<- CAT_EOF
	.timeout 10000
	
	insert into last select * from sensors where sensorid = '${sensorid}';
	insert into sensors values(${now},'${sensorid}',${value});

	-- Update the fake sensor FFFF
	
	insert into last select * from sensors where sensorid = 'FFFF';
	insert into sensors values(
		${now},
		'FFFF',
		(select avg(Temp) from real_rensors_v)
	);

CAT_EOF


exit 0

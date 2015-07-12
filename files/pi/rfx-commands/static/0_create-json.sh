#!/bin/bash

#---------------------------------------------------------------------
#
#	Created by: Johan Samuelson - Diversify - 2014
#
#	$Id:$
#
#	$URL:$
#
#---------------------------------------------------------------------

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${lastfile}" "${minfile}" "${maxfile}" "${minhumfile}" "${maxhumfile}"  "${stampfile}" "${systemfile}" "${loadfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#       Include some needed files...
#
######################################################################


######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"

lastfile="/tmp/`basename $0`-$$-last.tmp"

minfile="/tmp/`basename $0`-$$-min.tmp"
maxfile="/tmp/`basename $0`-$$-max.tmp"

minhumfile="/tmp/`basename $0`-$$-minhum.tmp"
maxhumfile="/tmp/`basename $0`-$$-maxhum.tmp"

stampfile="/tmp/`basename $0`-$$-stamp.tmp"

systemfile="/tmp/`basename $0`-$$-system.tmp"

loadfile="/tmp/`basename $0`-$$-oh-load.tmp"


openhabPidFile=/var/run/openhab.pid
now=$(date '+%F %T')

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)


#-------------------------------------------------------------------------------
#
#	Function formatSystemInfo
#
#-------------------------------------------------------------------------------

function formatSystemInfo ()
{
printf "%s\t%s\t%s\n" "${1}" "${2}" "${3}"
}



(

#
#	Collect info
#

#	Sensors variables: sensors_outdoor,sensors_indoor,sensors_humidity,sensors_all

source ${scriptDir}/../sensors.cfg

openHabPid=$(cat "${openhabPidFile}")


openhab_load="0.0"
openhab_restarted="0000-00-00 00:00:00"
openhab_status=""

loadavg="0.0  0.0  0.0"
core_temp="0 °C"
core_volts="0V"
uptime="21 days, 11:19:03"
wifi_restart=""

#	loadavg

loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

#	core
core_temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp | awk '{printf("%.2f °C",$0 / 1000.0)};')
core_volts=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')


#wifi_restart="$(awk 'END {print $1" "$2}' /var/log/WiFi_Check.log)"
wifi_restart=$(stat --printf=%z /run/sendsigs.omit.d/wpasupplicant.wpa_supplicant.wlan0.pid | awk -F. '{print $1}')

#	openhab
top -d 2 -p ${openHabPid} -n 5 -b > ${loadfile}
openhab_load=$(awk -v pid="${openHabPid}" 'BEGIN {s=0;c=1} $1 ~ pid {s += $9;c++} END {printf("%.1f",s / c);}' ${loadfile})
#openhab_restarted=$(egrep '^20' /var/rfxcmd/openhab-restart.log | tail -1 | awk '{print $1" "$2}')
openhab_restarted=$(stat --printf=%z /var/run/openhab.pid | awk -F. '{print $1}')
openhab_status=$(${scriptDir}/../scripts/check-openhab-online.sh | awk '{print $3}')

uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`



#	Last stamp

mysql rfx --skip-column-names -urfxuser -prfxuser1 < ${scriptDir}/sql/last-stamp.sql > "${stampfile}"


#
#	Create the systemfile
#

{
formatSystemInfo "section" "key" "value"

formatSystemInfo "pi" "openhab_load"		"${openhab_load} %"
formatSystemInfo "pi" "openhab_restarted"	"${openhab_restarted}"
formatSystemInfo "pi" "openhab_status"		"${openhab_status}"
formatSystemInfo "pi" "uptime"			"${uptime}"
formatSystemInfo "pi" "core_temp"		"${core_temp}"
formatSystemInfo "pi" "core_volts"		"${core_volts}"
formatSystemInfo "pi" "loadavg"			"${loadavg}"
formatSystemInfo "pi" "wifi_restart"		"${wifi_restart}"

formatSystemInfo "static" "timestamp" "${now}" 

#	Sql stuff

cat "${stampfile}"


} > "${systemfile}"



#
#	Last, min and max temps
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/last-temps.sql;" > "${lastfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/min-today.sql;" > "${minfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/max-today.sql;" > "${maxfile}"


#	Append tnu data i.e fake sensor FFFF

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-last-temp.sql;" >> "${lastfile}"

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-min-today.sql;" >> "${minfile}"

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-max-today.sql;" >> "${maxfile}"


#
#	Humidity
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_humidity:='${sensors_humidity}'; source ${scriptDir}/sql/min-humidity-today.sql;" > "${minhumfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_humidity:='${sensors_humidity}'; source ${scriptDir}/sql/max-humidity-today.sql;" > "${maxhumfile}"


#
#	Convert to json suitable for ExtJS
#

python -u ${scriptDir}/1_data-to-json.py \
        --last-file     "${lastfile}" \
        --min-file      "${minfile}" \
        --max-file      "${maxfile}" \
        --min-hum-file  "${minhumfile}" \
        --max-hum-file  "${maxhumfile}" \
        --system-file   "${systemfile}" \
	
) > "${tmpfile}" && cat "${tmpfile}"



exit 0

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

trap 'rm -f "${tmpfile}" "${lastfile}" "${minfile}" "${maxfile}" "${minhumfile}" "${maxhumfile}"  "${stampfile}" "${systemfile}" "${loadfile}" "${switchfile}" "${citiestmpfile}" "${scantmpfile}" "${hitsfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15



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
hitsfile="/tmp/`basename $0`-$$-hits.tmp"

systemfile="/tmp/`basename $0`-$$-system.tmp"

loadfile="/tmp/`basename $0`-$$-oh-load.tmp"
switchfile="/tmp/`basename $0`-$$-switches.tmp"

citiestmpfile="/tmp/cities.json"
scantmpfile="/tmp/`basename $0`-$$-scan.tmp"



openhabPidFile=/var/run/openhab.pid
now=$(date '+%F %T')
runCounter="-1"
destFile="/dev/stdout"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg
sensors=${scriptDir}/../sensors.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }
[ -r ${sensors} ]  && source ${sensors}    || { logger -t $(basename $0) "FATAL: Missing '${sensors}', Aborting" ; exit 1; }


#-------------------------------------------------------------------------------
#
#	Function formatSystemInfo
#
#-------------------------------------------------------------------------------

function formatSystemInfo ()
{
printf "%s\t%s\t%s\n" "${1}" "${2}" "${3}"
}


#       We want all output appended to the log..

exec >> ${UPDATE_REST_LOG} 2>&1 



#
#   Parse parameters
#

	while getopts "c:d:" opt
	do
        	case $opt in
            	c) runCounter=$OPTARG;;
            	d) destFile=$OPTARG;;
            	*) exit 0 ;;
        	esac
	done

shift `expr ${OPTIND} - 1` ; OPTIND=1


#
#	Collect info
#

#	Sensors variables: sensors_outdoor,sensors_indoor,sensors_humidity,sensors_all


openHabPid=$(cat "${openhabPidFile}")


openhab_load="0.0"
openhab_restarted="0000-00-00 00:00:00"
openhab_status=""

loadavg="0.0  0.0  0.0"
core_temp="0 °C"
core_volts="0V"
uptime="21 days, 11:19:03"
wifi_restart=""


log "Collect from openhab..."

#	openhab

top -d 2 -p ${openHabPid} -n 5 -b > ${loadfile}
openhab_load=$(awk -v pid="${openHabPid}" 'BEGIN {s=0;c=1} $1 ~ pid {s += $9;c++} END {printf("%.1f",s / c);}' ${loadfile})
openhab_restarted=$(stat --printf=%z /var/run/openhab.pid | awk -F. '{print $1}')
openhab_status=$(${scriptDir}/../scripts/check-openhab-online.sh | awk '{print $3}')

log "Collect from host(s)..."

#	loadavg

loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

#	core

core_temp_raw=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp)
core_temp=$(python -c 'import sys;print u"{:.1f} \u00b0C".format(float(sys.argv[1]) / 1000.0).encode("utf-8")' ${core_temp_raw})

core_volts=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')


wifi_restart=$(stat --printf=%z /run/sendsigs.omit.d/wpasupplicant.wpa_supplicant.wlan0.pid | awk -F. '{print $1}')
wifi_link=$(cat /proc/net/wireless | awk '$1 ~ /wlan0/ {gsub(/\./,"");print $3}')
wifi_level=$(cat /proc/net/wireless | awk '$1 ~ /wlan0/ {gsub(/\./,"");print $4}')


uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`



#	Last stamp

mysql rfx --skip-column-names -urfxuser -prfxuser1 < ${scriptDir}/sql/last-stamp.sql > "${stampfile}"


# 	Public ip

public_ip="???"
curl -s --connect-timeout 5 --max-time 5 "https://api.ipify.org" > "${tmpfile}" 2>/dev/null

if [ -s "${tmpfile}" ] ; then
	public_ip=$(cat "${tmpfile}")
fi

 
#	Last boot

last_boot=$(who -b | awk '{print $3" "$4":00"}')

#	Last rfxcmd/pubnubmgr restart

rfxcmd_restart=$(stat --printf=%z /var/run/rfxcmd.pid | awk -F. '{print $1}')
pubnubmgr_restart=$(stat --printf=%z /var/run/pubnubmgr.pid | awk -F. '{print $1}')

#	Any updates ?

updates=0
updates_file="/tmp/$(uname -n)-updates.txt"

if [ -r "${updates_file}" ] ; then
	updates=$(awk 'END {print NR}' ${updates_file})
fi

 
#
#	Create the systemfile
#

{
formatSystemInfo "section" "key" "value"

formatSystemInfo "openhab" "load"	"${openhab_load} %"
formatSystemInfo "openhab" "restarted"	"${openhab_restarted}"
formatSystemInfo "openhab" "status"	"${openhab_status}"

formatSystemInfo "pi" "uptime"	        "${uptime}"
formatSystemInfo "pi" "updates"	        "${updates}"
formatSystemInfo "pi" "core_temp"       "${core_temp}"
formatSystemInfo "pi" "core_volts"      "${core_volts}"
formatSystemInfo "pi" "loadavg"	        "${loadavg}"
formatSystemInfo "pi" "wifi_restart"    "${wifi_restart}"
formatSystemInfo "pi" "wifi_link"       "${wifi_link}"
formatSystemInfo "pi" "wifi_level"      "${wifi_level}"
formatSystemInfo "pi" "public_ip"       "${public_ip}"
formatSystemInfo "pi" "last_boot"       "${last_boot}"

formatSystemInfo "static" "timestamp"	"${now}" 

formatSystemInfo "misc" "rfxcmd_last_restart"    "${rfxcmd_restart}"
formatSystemInfo "misc" "pubnubmgr_last_restart" "${pubnubmgr_restart}"

cat "${stampfile}"

#   Collect from mint-black
curl -s --connect-timeout 5 --max-time 5 'http://mint-black:5000/collect/collect.php' 2> /dev/null

#Collect from smultronet
ssh pi@smultronet ~/bin/smultronet.sh
  

} > "${systemfile}"

log "Collect from host(s) done..."


#
#	Get coldest/warmest cities
#

if [ -n "${runCounter}" ] && [[ $(( ${runCounter} % 2)) -eq 0 ]] ; then
	log "Counter % 2 -> Fetch warmest/coldest cities"
	call -o ${citiestmpfile} ${scriptDir}/../cities/top-cities.sh 
	to_static ${citiestmpfile} 
fi


#
#	Get nmap data
#

log "Wait for nmap scan to finish..."

(
flock -x -w 180 300 || logger -t "${0}" "Failed to aquire lock for nmap"
mysql nmap -urfxuser -prfxuser1 \
	-e "source ${scriptDir}/../nmap/sql/scan.sql;" > "${scantmpfile}"
) 300> /var/lock/nmap.lock

log "Got nmap results..."

#	Sql stuff

log "Collect from mysql..."

#
#	Last,min and max temps
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/last-temps.sql;" > "${lastfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/min-today.sql;" > "${minfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_all:='${sensors_all}'; source ${scriptDir}/sql/max-today.sql;" > "${maxfile}"

#   Number of hits during the last hour

mysql rfx -urfxuser -prfxuser1 \
	-e "source ${scriptDir}/sql/last-hour-count.sql;" > "${hitsfile}"

#	Append tnu data i.e fake sensor 0000

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-last-temp.sql;" >> "${lastfile}"

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-min-today.sql;" >> "${minfile}"

mysql tnu -urfxuser -prfxuser1 --skip-column-names \
	-e "source ${scriptDir}/sql/tnu-max-today.sql;" >> "${maxfile}"

#	Append median data i.e fake sensor 0001

mysql rfx -urfxuser -prfxuser1 --skip-column-names \
	-e "set @sensors_outdoor:='${sensors_outdoor}'; source ${scriptDir}/sql/median-outdoor.sql;" >> "${lastfile}"
 
#
#	Humidity
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_humidity:='${sensors_humidity}'; source ${scriptDir}/sql/min-humidity-today.sql;" > "${minhumfile}"

mysql rfx -urfxuser -prfxuser1 \
	-e "set @sensors_humidity:='${sensors_humidity}'; source ${scriptDir}/sql/max-humidity-today.sql;" > "${maxhumfile}"

#
#	State of all switches
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @switches_all:='${switches_all}'; source ${scriptDir}/sql/last-switches.sql;" > "${switchfile}"


log "Collect from mysql done..."


#
#	Convert to json
#

log "Calling '$(basename ${scriptDir}/1_data-to-json.py)'..."

(
python -u ${scriptDir}/1_data-to-json.py \
        --last-file      "${lastfile}" \
        --min-file       "${minfile}" \
        --max-file       "${maxfile}" \
        --min-hum-file   "${minhumfile}" \
        --max-hum-file   "${maxhumfile}" \
        --system-file    "${systemfile}" \
        --switch-file    "${switchfile}" \
        --cities-file    "${STATIC_DIR}/cities.json" \
	--tnu-sensors    "${sensors_tnu}" \
	--macs           "${ALL_MACS}" \
	--devices-file   "${scantmpfile}" \
	--missing        "${STATIC_DIR}/signal-history.json" \
        --hits-file      "${hitsfile}" \
	--device-max-age "${DEVICES_MAX_AGE}"
) > ${destFile} 2>&1

exit 0

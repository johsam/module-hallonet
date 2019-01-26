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

tmpfile="/tmp/`basename $0`-$$.tmp"

has_version_file="/tmp/has_version.txt"
has_latest_file="/tmp/has_version_latest.txt"
updates_file="/tmp/$(uname -n)-updates.txt"

#-------------------------------------------------------------------------------
#
#	Function formatSystemInfo
#
#-------------------------------------------------------------------------------

function formatSystemInfo ()
{
printf "%s\t%s\t%s\n" "${1}" "${2}" "${3}"
}

#
#	Collect data
#

hour="$(date +%H)"
runCounter=$(( ($(date +%_H) * 6)  + ($(date +%_M) / 10) ))

loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

#	core

core_temp_raw=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp)
core_temp=$(python -c 'import sys;print u"{:.1f} \u00b0C".format(float(sys.argv[1]) / 1000.0).encode("utf-8")' ${core_temp_raw})
core_volts=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')

gpu_temp_raw=$(/opt/vc/bin/vcgencmd measure_temp | tr -cd '[0-9\.]')
gpu_temp=$(python -c 'import sys;print u"{:.1f} \u00b0C".format(float(sys.argv[1])).encode("utf-8")' ${gpu_temp_raw})

uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(uptime -s)
release="$(lsb_release -c -r -s | tr '\n' ' ')"



#
#	Home Assistant
#

/usr/sbin/service home-assistant status > ${tmpfile}

has_started=$(awk '$1 ~ /Active/ {print $6" "$7}' ${tmpfile})
has_status=$(awk '$1 ~ /Active/ {print $3}' ${tmpfile} | tr -d '()')
has_version=$(curl -s http://localhost:8123/api/config | jq -r .version)
has_host="$(uname -n)"

#	Clear cache

if [[ $(( ${runCounter} % 36)) -eq 0 ]] ; then
	rm -f ${has_version_file} ${has_latest_file}
fi


#	Create cache files if needed

if [ ! -r "${has_version_file}" ] ; then
	
	echo "?" > ${has_version_file}
	
	(
	curl -s http://localhost:8123/api/config | jq -r .version > ${tmpfile} 
	) 2> /dev/null ; status=$?
	if [ ${status} -eq 0 ] ; then
		cp ${tmpfile} ${has_version_file}
	fi
fi

if [ ! -r "${has_latest_file}" ] ; then

	echo "${has_version}" > ${has_latest_file}

	#echo "?" > ${has_latest_file}
	
	#(
	#curl -s https://pypi.python.org/pypi/homeassistant/json | jq -r .info.version > ${tmpfile}
	#) 2> /dev/null ; status=$?

	#if [ ${status} -eq 0 ] ; then
	#	cp ${tmpfile} ${has_latest_file}
	#fi

fi

has_version="$(cat ${has_version_file})"
has_latest_version="$(cat ${has_latest_file})"


if [ "${has_version}" != "${has_latest_version}" ] ; then
	has_version="|${has_version} -> ${has_latest_version}"
fi

if [ "${has_status}" != "running" ] ; then
	has_status="!${has_status}"
fi

#	Any updates ?

updates=0

if [ -r "${updates_file}" ] ; then
	updates=$(awk 'END {print NR}' ${updates_file})
fi


# Warn if up more than 14/21 days

prefix=""
[[ ${uptimeseconds} -gt 1209600 ]] && prefix="|"
[[ ${uptimeseconds} -gt 1814400 ]] && prefix="!"
uptime="${prefix}${uptime}"


#
#   Get data from influxdb
#


curl -s 'http://mint-fuji:8086/query?q=select+last(azimuth)+from+%22sun.sun%22&db=home_assistant' > ${tmpfile} 2>/dev/null

if [ -s "${tmpfile}" ] ; then
    last_infludb_data=$(jq '.results[].series[].values[0][0]' ${tmpfile} 2>/dev/null)
fi

last_infludb_data=${last_infludb_data:="1970-01-01"}

infludb_date=$(echo ${last_infludb_data} | xargs date "+%F %T" -d 2>/dev/null)

#
#	Done...
#

formatSystemInfo "pib" "uptime"	     "${uptime}"
formatSystemInfo "pib" "core_temp"   "${core_temp}"
formatSystemInfo "pib" "core_volts"  "${core_volts}"
formatSystemInfo "pib" "gpu_temp"    "${gpu_temp}"
formatSystemInfo "pib" "loadavg"     "${loadavg}"
formatSystemInfo "pib" "last_boot"   "${last_boot}"
formatSystemInfo "pib" "release"     "${release}"
formatSystemInfo "has" "started"     "${has_started}"
formatSystemInfo "has" "status"      "${has_status}"
formatSystemInfo "has" "version"     "${has_version}"
formatSystemInfo "has" "host"        "${has_host}"
formatSystemInfo "has" "influxdata"  "${infludb_date}"
formatSystemInfo "updates" "pib"     "${updates}"

#
#	YR weather data
#

curl -s http://localhost:8123/api/states | jq -r '.[] | select(.entity_id| contains("sensor.yr")) | "yr\t" + .entity_id + "\t" + .state + " " + .attributes.unit_of_measurement' | sort


exit 0

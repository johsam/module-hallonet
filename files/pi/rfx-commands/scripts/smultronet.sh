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

#-------------------------------------------------------------------------------
#
#	Function formatSystemInfo
#
#-------------------------------------------------------------------------------

function formatSystemInfo ()
{
printf "%s\t%s\t%s\n" "${1}" "${2}" "${3}"
}


loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

#	core
core_temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp | awk '{printf("%.2f °C",$0 / 1000.0)};')
core_volts=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')


wifi_restart=$(stat --printf=%z /run/sendsigs.omit.d/wpasupplicant.wpa_supplicant.wlan0.pid | awk -F. '{print $1}')
wifi_link=$(cat /proc/net/wireless | awk '$1 ~ /wlan0/ {gsub(/\./,"");print $3}')
wifi_level=$(cat /proc/net/wireless | awk '$1 ~ /wlan0/ {gsub(/\./,"");print $4}')


uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(uptime -s)

/usr/sbin/service home-assistant status > ${tmpfile}

ha_started=$(awk '$1 ~ /Active/ {print $6" "$7}' ${tmpfile})
ha_status=$(awk '$1 ~ /Active/ {print $3}' ${tmpfile} | tr -d '()')
 
formatSystemInfo "pib" "uptime"	      "${uptime}"
formatSystemInfo "pib" "core_temp"    "${core_temp}"
formatSystemInfo "pib" "core_volts"   "${core_volts}"
formatSystemInfo "pib" "loadavg"      "${loadavg}"
formatSystemInfo "pib" "wifi_restart" "${wifi_restart}"
formatSystemInfo "pib" "wifi_link"    "${wifi_link}"
formatSystemInfo "pib" "wifi_level"   "${wifi_level}"
formatSystemInfo "pib" "last_boot"    "${last_boot}"
formatSystemInfo "has"  "started"     "${ha_started}"
formatSystemInfo "has"  "status"      "${ha_status}"

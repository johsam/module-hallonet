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

uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(uptime -s)


#	Any updates ?

updates=0

if [ -r "${updates_file}" ] ; then
	updates=$(awk 'END {print NR}' ${updates_file})
fi

#
#	Done...
#

formatSystemInfo "pij" "uptime"	     "${uptime}"
formatSystemInfo "pij" "core_temp"   "${core_temp}"
formatSystemInfo "pij" "core_volts"  "${core_volts}"
formatSystemInfo "pij" "loadavg"     "${loadavg}"
formatSystemInfo "pij" "last_boot"   "${last_boot}"
formatSystemInfo "pij" "updates"     "${updates}"


exit 0

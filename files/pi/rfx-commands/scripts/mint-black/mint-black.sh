#!/bin/bash
export LC_ALL=en_US.UTF-8

degree=$(printf "\u00b0")

core_temp=$(sensors | awk '$1 ~/Core0/ {print $3}' | tr -cd '[0-9\.]')
loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)


uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(who -b | awk '{print $3" "$4":00"}')

#	Any updates ?

updates=0
updates_file="/tmp/$(uname -n)-updates.txt"

if [ -r "${updates_file}" ] ; then
	updates=$(awk 'END {print NR}' ${updates_file})
fi

# Warn if up more than 21 days

prefix=""
[[ ${uptimeseconds} -gt 1209600 ]] && prefix="|"
[[ ${uptimeseconds} -gt 1814400 ]] && prefix="!"
uptime="${prefix}${uptime}"
{
printf "%s\t%s\t%s\n" "mintblack" "core_temp" "${core_temp} ${degree}C"
printf "%s\t%s\t%s\n" "mintblack" "loadavg" "${loadavg}"
printf "%s\t%s\t%s\n" "mintblack" "uptime" "${uptime}"
printf "%s\t%s\t%s\n" "mintblack" "last_boot" "${last_boot}"

printf "%s\t%s\t%s\n" "updates" "mintblack" "${updates}"
}

exit 0

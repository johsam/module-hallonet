#!/bin/bash
export LC_ALL=en_US.UTF-8

degree=$(printf "\u00b0")

core_temp=$(sensors -u | awk '$1 ~/.*input/ {sum +=$2; cnt++}END{printf("%.1f", sum/cnt)}')
loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(who -b | awk '{print $3" "$4":00"}')

#       Any updates ?

updates=0
updates_file="/tmp/$(uname -n)-updates.txt"

if [ -r "${updates_file}" ] ; then
        updates=$(awk 'END {print NR}' ${updates_file})
fi


{
printf "%s\t%s\t%s\n" "mintfuji" "core_temp" "${core_temp} ${degree}C"
printf "%s\t%s\t%s\n" "mintfuji" "loadavg" "${loadavg}"
printf "%s\t%s\t%s\n" "mintfuji" "uptime" "${uptime}"
printf "%s\t%s\t%s\n" "mintfuji" "updates" "${updates}"
printf "%s\t%s\t%s\n" "mintfuji" "last_boot" "${last_boot}"
}


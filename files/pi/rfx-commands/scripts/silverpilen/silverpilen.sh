#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

tmpfile="/tmp/`basename $0`-$$.tmp"

export LC_ALL=en_US.UTF-8

degree=$(printf "\u00b0")

core_temp=$(sensors -u | awk '$1 ~/.*input/ {sum +=$2; cnt++}END{printf("%.1f", sum/cnt)}')
loadavg=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

uptimeseconds=$(awk -F'.' '{print $1}' /proc/uptime)
uptime=`python3 -u -c "import sys;from datetime import timedelta; print(timedelta(seconds = ${uptimeseconds}))"`

last_boot=$(who -b | awk '{print $3" "$4":00"}')
release="$(lsb_release -c -r -s | tr '\n' ' ')"

#       Any updates ?

updates=0
updates_file="/tmp/$(uname -n)-updates.txt"

if [ -r "${updates_file}" ] ; then
        updates=$(awk 'END {print NR}' ${updates_file})
fi

# Warn if up more than 14/21 days

prefix=""
[[ ${uptimeseconds} -gt 1209600 ]] && prefix="|"
[[ ${uptimeseconds} -gt 1814400 ]] && prefix="!"
uptime="${prefix}${uptime}"

{
printf "%s\t%s\t%s\n" "silverpilen" "core_temp" "${core_temp} ${degree}C"
printf "%s\t%s\t%s\n" "silverpilen" "loadavg" "${loadavg}"
printf "%s\t%s\t%s\n" "silverpilen" "uptime" "${uptime}"
printf "%s\t%s\t%s\n" "silverpilen" "last_boot" "${last_boot}"
printf "%s\t%s\t%s\n" "silverpilen" "release" "${release}"

printf "%s\t%s\t%s\n" "updates" "silverpilen" "${updates}"
}


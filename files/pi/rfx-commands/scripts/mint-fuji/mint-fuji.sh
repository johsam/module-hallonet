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
uptime=`python -u -c "import sys;from datetime import timedelta; print timedelta(seconds = ${uptimeseconds})"`

last_boot=$(who -b | awk '{print $3" "$4":00"}')
release="$(lsb_release -c -r -s | tr '\n' ' ')"


/usr/sbin/service influxdb status > ${tmpfile}
influxdb_started=$(awk '$1 ~ /Active/ {print $6" "$7}' ${tmpfile})
influxdb_status=$(awk '$1 ~ /Active/ {print $3}' ${tmpfile} | tr -d '()')
influxdb_host="$(uname -n)"
influxdb_version=$(dpkg -s influxdb | awk '$1 ~ /Version/ {print $2}')

/usr/sbin/service grafana-server status > ${tmpfile} 2> /dev/null
grafana_started=$(awk '$1 ~ /Active/ {print $6" "$7}' ${tmpfile})
grafana_status=$(awk '$1 ~ /Active/ {print $3}' ${tmpfile} | tr -d '()')
grafana_host="$(uname -n)"
grafana_version=$(dpkg -s grafana | awk '$1 ~ /Version/ {print $2}')

rethinkdb_started=$(stat --printf=%z  /var/run/rethinkdb/default/pid_file  | awk -F. '{print $1}')
rethinkdb_host="$(uname -n)"
rethinkdb_version=$(dpkg -s rethinkdb | awk '$1 ~ /Version/ {print $2}')
[[ -r /var/run/rethinkdb/default/pid_file ]] && rethinkdb_status="runnig" || rethinkdb_status="stopped"

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
printf "%s\t%s\t%s\n" "mintfuji" "core_temp" "${core_temp} ${degree}C"
printf "%s\t%s\t%s\n" "mintfuji" "loadavg" "${loadavg}"
printf "%s\t%s\t%s\n" "mintfuji" "uptime" "${uptime}"
printf "%s\t%s\t%s\n" "mintfuji" "last_boot" "${last_boot}"
printf "%s\t%s\t%s\n" "mintfuji" "release" "${release}"

printf "%s\t%s\t%s\n" "influxdb" "host" "${influxdb_host}"
printf "%s\t%s\t%s\n" "influxdb" "status" "${influxdb_status}"
printf "%s\t%s\t%s\n" "influxdb" "started" "${influxdb_started}"
printf "%s\t%s\t%s\n" "influxdb" "version" "${influxdb_version}"


printf "%s\t%s\t%s\n" "grafana" "host" "${grafana_host}"
printf "%s\t%s\t%s\n" "grafana" "status" "${grafana_status}"
printf "%s\t%s\t%s\n" "grafana" "started" "${grafana_started}"
printf "%s\t%s\t%s\n" "grafana" "version" "${grafana_version}"

printf "%s\t%s\t%s\n" "rethinkdb" "host" "${rethinkdb_host}"
printf "%s\t%s\t%s\n" "rethinkdb" "status" "${rethinkdb_status}"
printf "%s\t%s\t%s\n" "rethinkdb" "started" "${rethinkdb_started}"
printf "%s\t%s\t%s\n" "rethinkdb" "version" "${rethinkdb_version}"

printf "%s\t%s\t%s\n" "updates" "mintfuji" "${updates}"
}


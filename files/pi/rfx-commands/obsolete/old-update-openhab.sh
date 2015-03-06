#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}"  > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

[ -h "$0" ] && dir=$(dirname `readlink $0`) || dir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"

(
date
sqlDir=${dir}/sql
sqlcacheDir=${dir}/cache
openhabPidFile=/var/run/openhab.pid

#
#	No need to run if openhab is not running
#

if [ ! -r "${openhabPidFile}" ] ; then
	echo "$(date +%T) openhab not running"
	exit 0
fi

openHabPid=$(cat "${openhabPidFile}")

#
#	Parse parameter(s)
#

OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "f" _opts
do
	case "${_opts}" in
	f) rm -f ${sqlcacheDir}/*.cache ;;
	?) exit 1 ;;
	esac
done
shift `expr $OPTIND - 1` ; OPTIND=1
[ "$1" = "--" ] && shift



#
#	Update openhab load and restart time
#

top -d 1 -p ${openHabPid} -n 3 -b > ${tmpfile}

load=$(awk -v pid="${openHabPid}" 'BEGIN {s=0;c=1} $1 ~ pid {s += $9;c++} END {printf("%.1f",s / c);}' ${tmpfile})

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/PI_openhab_load --data "${load} %"

restarted=$(egrep '^20' /var/rfxcmd/openhab-restart.log | tail -1 | awk '{print $1" "$2}')

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/PI_openhab_restarted --data "${restarted}"


#
# 	Update sysinfo
#

python -u ${dir}/scripts/sysinfo.py --openhab "localhost"


#
#	Update last timestamp 
#

/usr/bin/mysql rfx -urfxuser -prfxuser1 --skip-column-names < ${sqlDir}/last-stamp.sql > "${tmpfile}"

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/SQL_timestamp --data "$(cat ${tmpfile})"

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/STATIC_timestamp --data "$(date +%T)"

#
#	Harware info
#

core_temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp | awk '{printf("%.2f °C",$0 / 1000.0)};')
curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/PI_core_temp --data "${core_temp}"

core_volts=$(vcgencmd measure_volts core | awk -F'=' '{print $2}')
curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/PI_core_volts --data "${core_volts}"

#
#	Create cache dir if needed
#

[ ! -d "${sqlcacheDir}" ] && mkdir "${sqlcacheDir}"


for sql in min-today max-today last-temps ; do 
	
	#
	#	Create cache file if needed...
	#
	
	cacheName="${openHabPid}-${sql}.cache"
	
	[ ! -r "${sqlcacheDir}/${cacheName}" ] && touch "${sqlcacheDir}/${cacheName}"
	
	#echo "Checking '${sql}'..."
	
	/usr/bin/mysql rfx -urfxuser -prfxuser1 < ${sqlDir}/${sql}.sql > "${tmpfile}"

	diff "${tmpfile}" "${sqlcacheDir}/${cacheName}" > /dev/null 2>&1 ; status=$?
	
	# Only update if a change is detected
	
	if [ ${status} -ne 0 ] ; then
		python -u ${dir}/update-rest.py --file "${tmpfile}" --openhab "localhost"
		cp "${tmpfile}" "${sqlcacheDir}/${cacheName}"
	fi


done



sudo ${dir}/scripts/update-graphs.sh -1

) >> /var/rfxcmd/update-rest.log 2>&1

exit 0

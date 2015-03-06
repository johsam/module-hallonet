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
logfile=/var/rfxcmd/openhab-restart.log

exit 0

[ ! -r "/var/run/openhab.pid" ] && exit 0


[ ! -r "${logfile}" ] && touch "${logfile}" && chown pi:pi "${logfile}"

pid=$(cat /var/run/openhab.pid)

top -d 1 -p ${pid} -n 3 -b > ${tmpfile}

load=$(awk -v pid="${pid}" 'BEGIN {s=0;c=1} $1 ~ pid {s += $9;c++} END {printf("%.0f",s / c);}' ${tmpfile})


if [ ${load} -gt 40 ] ; then
	(
	echo "$(date '+%F %T') Restarting openhab due to hig load (${load}%)"
	/usr/sbin/service openhab restart
	) >> ${logfile} 2>&1
	
	#	Remove cache files
	
	rm -f /home/pi/rfx-commands/cache/*.cache
	
fi



exit 0


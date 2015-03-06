#!/bin/bash

umask 022

printf "$(date '+%F %T')\tstate\t($1 -> $2)\n" >> /var/rfxcmd/nexa-setstate.log

id=$1
onOff="$(echo "$2" | tr '[:lower:]' '[:upper:]')"


if [ "${onOff}" = "GROUP OFF" ] ; then
	${0} 1 off
	sleep 1
	${0} 2 off
	exit 0
fi

if [ "${onOff}" = "GROUP ON" ] ; then
	${0} 1 on
	sleep 1
	${0} 2 on
	exit 0
fi


/usr/bin/curl -s --header 'Content-Type: text/plain' --request POST --data "${onOff}" http://localhost:8080/rest/items/Nexa_${id}


exit 0

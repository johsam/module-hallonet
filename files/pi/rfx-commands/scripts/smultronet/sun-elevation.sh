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

source "${BASH_SOURCE%/*}/.env"

curl -s --connect-timeout 10 --max-time 10 -XGET -H "${AUTH}" 'http://localhost:8123/api/states/sun.sun' > ${tmpfile} 2> /dev/null


if [ -s "${tmpfile}" ] ; then

	elevation=$(jq -r '.attributes.elevation' < ${tmpfile})
	last_updated=$(jq -r '.last_updated' < ${tmpfile})
	
	if [ "${elevation}" != "null" ] && [ "${last_updated}" != "null" ] ; then
	
		epoch=$(date --date ${last_updated} "+%s")

		path="linux.$(uname -n).sun.elevation ${elevation} ${epoch}"

		echo $path | nc -q0 mint-black 2003
	
	else
		logger -t $(basename $0) "Failed to fetch sun data from home-assistant"
	
	fi
fi


exit 0

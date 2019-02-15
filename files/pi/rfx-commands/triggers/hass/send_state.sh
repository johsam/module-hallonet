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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)


tmpfile="/tmp/`basename $0`-$$.tmp"


settings=${scriptDir}/../../settings.cfg

# Sanity checks

[ -r ${settings} ] && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

umask 011
exec >> ${HASS_LOG} 2>&1

switch_id=${1}
switch_state=${2}

url="http://${HASS_HOST}:8123/api/states/switch.switch_${switch_id}"

# Fetch old state, keep attributes and contruct new json data with state

#{
#  "state": "on",
#  "attributes": {
#    "friendly_name": "Name of light...",
#    "icon": "mdi:lightbulb-on"
#  }
#}


curl -s -H "Content-Type: application/json" "${url}" | /usr/local/bin/jq --arg state "${switch_state}" '{state:$state, attributes:.attributes}' > ${tmpfile}

# And update hass with new state

curl -s -X POST -H "Content-Type: application/json" "${url}" -d @${tmpfile}

exit 0

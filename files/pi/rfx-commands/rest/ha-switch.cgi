#!/bin/bash

echo "Content-type: application/json"
echo ""

# We need som functions here...

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

source ${scriptDir}/cgi.sh


# Get params from QUERY_STRING

declare -A params ; get_query_string params

# Or from post 

get_post_string params

# Safe defaults

switchid=${params['id']:=1}
state=${params['state']:=''}

# Use flock to make sure that the send command finishes before the next query
(
flock -x -w 30 200 || { logger -t "$(basename $0)" "Failed to aquire lock for ${switchid}->${state}"; exit 1; }

# Run external script

if [ "$REQUEST_METHOD" = "POST" ] && [ "${state}" != '' ]; then
    state="$(echo "${state}" | tr '[:upper:]' '[:lower:]')"

    /home/pi/rfx-commands/commands/cmd-to-nexa.sh "${switchid}" "${state^}"
    
    # Might take some time so wait a while
    
    sleep 3
else
    state=$(/home/pi/rfx-commands/scripts/nexa-get-state.sh ${switchid} | sed -e 's/On/true/i' -e 's/Off/false/i')
    echo "{\"state\":\"${state}\"}"
fi
) 200> /var/lock/ha-switch.lock

exit 0

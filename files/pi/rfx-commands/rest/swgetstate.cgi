#!/bin/bash

echo "Content-type: text/plain"
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

# Run external script

/home/pi/rfx-commands/scripts/nexa-get-state.sh ${switchid}
exit 0

#!/bin/bash

#-------------------------------------------------------------------------------
#
#       Function get_query_string
#
#-------------------------------------------------------------------------------

get_query_string() {
  local q="$QUERY_STRING"
  local re1='^(\w+=\w+)&?'
  local re2='^(\w+)=(\w+)$'
  while [[ $q =~ $re1 ]]; do
    q=${q##*${BASH_REMATCH[0]}}
    [[ ${BASH_REMATCH[1]} =~ $re2 ]] && eval "$1+=([${BASH_REMATCH[1]}]=${BASH_REMATCH[2]})"
  done
}

# Get params

declare -A params ; get_query_string params

# Safe defaults

switchid=${params['id']:=1}

# Run external script

state=$(/home/pi/rfx-commands/scripts/nexa-get-state.sh ${switchid})

[[ ${state^} == "Off" ]] && echo 0 || echo 1

exit 0

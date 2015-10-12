#!/bin/bash

echo "Content-type: application/json"
echo ""


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

#for k in "${!params[@]}"
#do
#  v="${params[$k]}"
#  echo "$k : $v"
#done     

# Safe defaults

length=${params['length']:=10}
warnings=${params['warnings']:=0}

[ ${warnings} == '1' ] && args="-w -p" || args="-p"

# Run external script

/home/pi/rfx-commands/history/history.sh -l "${length}" "${args}"

exit 0

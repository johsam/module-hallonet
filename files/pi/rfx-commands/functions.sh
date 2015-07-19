#!/bin/bash

#-------------------------------------------------------------------------------
#
#	Function log
#
#-------------------------------------------------------------------------------

function log ()
{
printf "%s %s\n" "$(date '+%F %T')" "${1}"
}

#-------------------------------------------------------------------------------
#
#	Function to_openhab
#
#-------------------------------------------------------------------------------

function to_openhab ()
{
local info=${1}
local item=${2}
local value=${3}

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/${item} --data "${value}"

printf "$(date '+%F %T') ${info} -> ${item} = '${value}'\n"
}

#-------------------------------------------------------------------------------
#
#	Function switch_to_graphite
#
#-------------------------------------------------------------------------------

function switch_to_graphite ()
{
local id="${1}"
local state=$(echo "${2}" | sed -e 's/On/1/g' -e 's/Off/0/g')
local epoch="$(date +%s)"
local path="linux.hallonet.sensors.switches.${id} ${state} ${epoch}"

echo $path | nc -q0 mint-black 2003
}

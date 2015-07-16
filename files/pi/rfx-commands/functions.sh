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

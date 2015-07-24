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

#-------------------------------------------------------------------------------
#
#	Function upload_static dir file
#
#-------------------------------------------------------------------------------

function upload_static ()
{
local dir="${1}"
local file="${2}"

lftp -c "my_upload; put -O ${dir} ${file}" 
}


#-------------------------------------------------------------------------------
#
#	Function rm_static file
#
#-------------------------------------------------------------------------------

function rm_static ()
{
local file="${1}"
local status=0

lftp -c "my_upload; rm ${file}" > /dev/null 2>&1; status=$?

return ${status}
}

#-------------------------------------------------------------------------------
#
#	Function find_static dir file
#
#-------------------------------------------------------------------------------

function find_static ()
{
local dir="${1}"
local file="${2}"
local status=0

lftp -c "my_upload; cd ${dir} ;find ${file}" > /dev/null 2>&1; status=$?

return ${status}
}


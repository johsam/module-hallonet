#!/bin/bash

#-------------------------------------------------------------------------------
#
#	Function plainlog
#
#-------------------------------------------------------------------------------

function plainlog ()
{
printf "%s %s\n" "$(date '+%F %T')" "${1}"
}
 

#-------------------------------------------------------------------------------
#
#	Function log
#
#-------------------------------------------------------------------------------

function log ()
{
local _pname="$(basename -- $0)"
local _fname="${FUNCNAME[1]}"
local _pad=$(seq -s' ' $((${SHLVL} - 1)) | tr -d '[:digit:]')

if [ "${_fname}" != "main" ] ; then
	printf "%s %s %s\n" "$(date '+%F %T')" "${_pad}[${_pname}:${_fname}]" "${1}"
else
	printf "%s %s %s\n" "$(date '+%F %T')" "${_pad}[${_pname}]" "${1}"
fi
}


#-------------------------------------------------------------------------------
#
#	Function command_verbose
#
#-------------------------------------------------------------------------------

function command_verbose ()
{
local magnet_command="${1}"
local magnet_type="${2}"
local utf8_str="${1}"

case ${magnet_type} in
    "door")
    	if [ "${magnet_command}" = "Off" ] ; then
    	    utf8_str="$(echo "Stängd" | iconv -f ISO-8859-15 -t UTF-8)"
	else
	    utf8_str="$(echo "Öppen" | iconv -f ISO-8859-15 -t UTF-8)"
	fi
    ;;
    
    "ir")
     	if [ "${magnet_command}" = "Off" ] ; then
    	    utf8_str="Passiv"
	else
	    utf8_str="Aktiv"
	fi
    ;;
    
    "light")
      	if [ "${magnet_command}" = "Off" ] ; then
    	    utf8_str="Av"
	else
	    utf8_str="$(echo "På" | iconv -f ISO-8859-15 -t UTF-8)"
	fi
    ;;
 
    "duskdawn")
     	if [ "${magnet_command}" = "Off" ] ; then
    	    utf8_str="Dag"
	else
	    utf8_str="Natt"
	fi
    ;;


esac
 
echo "${utf8_str}"
}

#-------------------------------------------------------------------------------
#
#	Function call
#
#-------------------------------------------------------------------------------

function call ()
{
local _append
local _output

#
#   Parse parameters
#

while getopts "a:o:" opt
do
        case $opt in
            a) _append=$OPTARG;;
            o) _output=$OPTARG;;
            *) exit 0 ;;
        esac
done

shift `expr ${OPTIND} - 1` ; OPTIND=1


local _script="${1}"
shift
local _args="${@}"
local _dir="$(basename $(dirname ${_script}))"

log "${_dir}/$(basename ${_script}) ${_args}" 

[ -n "${_append}" ] && ${_script} ${_args} >> ${_append}
[ -n "${_output}" ] && ${_script} ${_args} > ${_output}
[ -z "${_append}" ] && [ -z "${_output}" ] && ${_script} ${_args}
}

#-------------------------------------------------------------------------------
#
#	Function to_openhab
#
#-------------------------------------------------------------------------------

function to_openhab ()
{
local item=${1}
local value=${2}

curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/${item} --data "${value}"

log "${item}='${value}'"
}

#-------------------------------------------------------------------------------
#
#	Function to_graphite
#
#-------------------------------------------------------------------------------

function to_graphite ()
{
local id="${1}"
local state=$(echo "${2}" | sed -e 's/On/1/g' -e 's/Off/0/g')
local epoch="$(date +%s)"
local path="linux.hallonet.sensors.switches.${id} ${state} ${epoch}"

echo $path | nc -q0 mint-black 2003

log "Sending ${id}->${state}"
}

#-------------------------------------------------------------------------------
#
#	Function sw_to_influxdb
#
#-------------------------------------------------------------------------------

function sw_to_influxdb ()
{
local id="${1}"
local state=$(echo "${2}" | sed -e 's/On/1/gi' -e 's/Off/0/gi')
local type=${swtype[${id}]:='door'}
local id_id="ID_${id}"
local alias="$(echo ${!id_id} | iconv -f ISO-8859-15 -t UTF-8)"
local influxtime="${3}"

curl -s -XPOST 'http://mint-fuji:8086/write?db=ripan' --data-binary "switches,id=${id},alias=${alias// /\\ },type=${type} value=${state} ${influxtime}"

log "Sending '${alias}'->${id}->${2}"
}


#-------------------------------------------------------------------------------
#
#	Function light_to_influxdb
#
#-------------------------------------------------------------------------------

function light_to_influxdb ()
{
local id="${1}"
local state=$(echo "${2}" | sed -e 's/On/1/gi' -e 's/Off/0/gi')
local id_id="ID_${id}"
local alias="$(echo ${!id_id} | iconv -f ISO-8859-15 -t UTF-8)"
local influxtime="${3}"

curl -s -XPOST 'http://mint-fuji:8086/write?db=ripan' --data-binary "lights,id=${id},alias=${alias// /\\ } state=${state} ${influxtime}"

log "Sending '${alias}'->${id}->${2}"
}


#-------------------------------------------------------------------------------
#
#	Function to_webroot dir file
#
#-------------------------------------------------------------------------------

function to_webroot ()
{
local dir="${1}"
local file="${2}"

lftp -c "my_upload; put -O ${dir} ${file}"
log "Saved '$(basename ${file})' to webroot" >> ${UPDATE_REST_LOG}
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


#-------------------------------------------------------------------------------
#
#	Function to_static file
#
#-------------------------------------------------------------------------------

function to_static ()
{
local file="${1}"
local dest="${STATIC_DIR}/$(basename ${file})"

if [ -w "${STATIC_DIR}" ] ; then
	
	if [ "${file}" != "${dest}" ] ; then
		#logger "${file} -> ${dest}"
		cp -p ${file} "${STATIC_DIR}/"
		log "Saved '$(basename ${file})' to static" >> ${UPDATE_REST_LOG}
	fi
else
	logger -t $(basename $0) "Could not write to '${STATIC_DIR}'"
fi

return 0

#	NAS


if [ -w "${STATIC_NASDIR}" ] ; then
	cp ${file} "${STATIC_NASDIR}/"
	log "Saved '$(basename ${file})' to NAS" >> ${UPDATE_REST_LOG}

else 
	logger -t $(basename $0) "Could not write to '${STATIC_NASDIR}'"
fi


return 0
}

#-------------------------------------------------------------------------------
#
#	Function pn_gw_publish channel file
#
#-------------------------------------------------------------------------------

function pn_gw_publish ()
{
local channel="${1}"
local file="${2}"
local status=0

curl -s -k --connect-timeout 5 --max-time 5 -XPOST "http://${PN_GW_HOST}:${PN_GW_PORT}/publish/${channel}" -d @${file} 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

return ${status}
}

#-------------------------------------------------------------------------------
#
#	Function pn_gw_message message
#
#-------------------------------------------------------------------------------

function pn_gw_message ()
{
local message="${1}"

curl -s -k --connect-timeout 5 --max-time 5 -XPOST "http://${PN_GW_HOST}:${PN_GW_PORT}/send/message/${PUBNUB_CHANNEL_SENSORS}" \
	-d "{\"message\": \"${message}\"}" > /dev/null 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

return ${status}
}

#-------------------------------------------------------------------------------
#
#	Function pn_gw_notice message
#
#-------------------------------------------------------------------------------

function pn_gw_notice ()
{
local message="${1}"

curl -s -k --connect-timeout 5 --max-time 5 -XPOST "http://${PN_GW_HOST}:${PN_GW_PORT}/send/notify/${PUBNUB_CHANNEL_SENSORS}" \
	-d "{\"message\": \"${message}\"}" > /dev/null 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

return ${status}
}


#-------------------------------------------------------------------------------
#
#	Function pn_gw_refresh 
#
#-------------------------------------------------------------------------------

function pn_gw_refresh ()
{

curl -s -k --connect-timeout 5 --max-time 5 -XPOST "http://${PN_GW_HOST}:${PN_GW_PORT}/send/refresh/${PUBNUB_CHANNEL_SENSORS}" \
	-d '{}' > /dev/null 2>> "${PUBNUB_ERROR_LOG}" ; status=$?

return ${status}
}


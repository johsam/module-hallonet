#!/bin/bash

#---------------------------------------------------------------------
#
#	Created by: Johan Samuelson - Diversify - 2014
#
#	$Id:$
#
#	$URL:$
#
#---------------------------------------------------------------------

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${jsontmpfile}" "${csvtmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#       Include some needed files...
#
######################################################################


######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"

jsontmpfile="/tmp/sensors.json"
csvtmpfile="/tmp/openhab.csv"
citiestmpfile="/tmp/cities.json"

runCounter="0"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }



#
#   Parse parameters
#

if [ $# -gt 1 ] ; then
	while getopts "c:" opt
	do
        	case $opt in
            	c) runCounter=$OPTARG;;
            	*) exit 0 ;;
        	esac
	done
fi
shift `expr ${OPTIND} - 1` ; OPTIND=1



#
#	Start collecting data
#

log "Collecting data..."
call ${scriptDir}/0_create-json.sh -c "${runCounter}" -d ${jsontmpfile}

#
#	Use flock to prevent any script to manipulate sensors.json
#
(
flock -x -w 30 200 || { logger -t "${0}" "Failed to aquire lock for ${jsontmpfile}"; exit 1; }

log "Uploading json..."
to_webroot static ${jsontmpfile}

log "Backup $(basename ${jsontmpfile}) to NAS..."
to_static ${jsontmpfile}

) 200> /var/lock/sensor.lock


#	Openhab

log "Convert json to csv..."
call -o ${csvtmpfile} ${scriptDir}/2_json-to-csv.py --file ${jsontmpfile}

log "Backup $(basename ${csvtmpfile}) to NAS..."
to_static ${csvtmpfile}


log "Upload csv to openhab..."

call ${scriptDir}/3_csv-to-openhab.py --file ${csvtmpfile}


exit 0

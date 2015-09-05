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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)
[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)

#
#	Start collecting data
#

log "Collecting data..."
${scriptDir}/0_create-json.sh > ${jsontmpfile}

#
#	Use flock to prevent any script to manipulate sensors.json
#
(
flock -x -w 30 200 || {logger "Failed to aquire lock for ${jsontmpfile}"; exit 1;}

log "Uploading json..."
upload_static static ${jsontmpfile}

log "Backup $(basename ${jsontmpfile}) to NAS..."
backup_to_static ${jsontmpfile}

) 200> /var/lock/sensor.lock


#	Openhab

log "Convert json to csv..."
python -u ${scriptDir}/2_json-to-csv.py --file ${jsontmpfile} > ${csvtmpfile}

log "Backup $(basename ${csvtmpfile}) to NAS..."
backup_to_static ${csvtmpfile}


log "Upload csv to openhab..."

python -u ${scriptDir}/3_csv-to-openhab.py --file ${csvtmpfile}


exit 0

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

savetojson="/mnt/nas-backup/statics/sensors.json"
savetocsv="/mnt/nas-backup/statics/openhab.csv"

jsontmpfile="/tmp/sensors.json"
csvtmpfile="/tmp/sensors.csv"

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)


#-------------------------------------------------------------------------------
#
#	Function log
#
#-------------------------------------------------------------------------------

function log ()
{
printf "%s %s\n" "$(date '+%F %T')" "${1}"
}



log "Collecting data..."
${scriptDir}/0_create-json.sh > ${jsontmpfile}

log "Uploading json..."
lftp -c "open -u surjohan,yadast ftp.bredband.net; put -O static ${jsontmpfile}" 


log "Convert json to csv..."
python -u ${scriptDir}/2_json-to-csv.py --file ${jsontmpfile} > ${csvtmpfile}


log "Upload csv to openhab..."

python -u ${scriptDir}/3_csv-to-openhab.py --file ${csvtmpfile}

#	Backup

log "Backup to NAS..."

cp ${jsontmpfile} ${savetojson}
cp ${csvtmpfile} ${savetocsv}

exit 0

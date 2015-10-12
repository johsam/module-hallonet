#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${jsonfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
jsonfile="/tmp/signal-history.json"

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }


threshold=40
days=2

#	Parse parameters
#

while getopts "t:d:" opt
do
        case $opt in
            t) threshold="${OPTARG}";;
            d) days="${OPTARG}";;
            \?) usage ;;
            *) usage ;;
        esac
done

shift `expr ${OPTIND} - 1` ; OPTIND=1

#
#	History of all hours with missing signals, i.e count < threshold
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @threshold:=${threshold}; set @days:=${days}; source ${scriptDir}/sql/signal.sql;" > "${tmpfile}"


#
#	Use flock to prevent any script to manipulate sensors.json while we read
#

(
flock -x -w 30 200 || { logger "Failed to aquire lock for ${jsonfile}"; exit 1; }

#	Convert to json

python -u ${scriptDir}/csv-to-json.py --file ${tmpfile} --sensors ${JSON_FILE} > ${jsonfile}

) 200> /var/lock/sensor.lock

#cat ${jsonfile}

#exit
#
#	Save data
#

upload_static static/ ${jsonfile} 2> /dev/null
backup_to_static ${jsonfile} 2> /dev/null

#	And return result

cat ${jsonfile}

exit 0

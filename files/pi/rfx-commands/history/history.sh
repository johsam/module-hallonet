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
jsonfile="/tmp/switch-history.json"

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }


histlen=30
signals="0,1,2,3,4,5,6,7,8,9"
arg_count=10
args=""

#	Parse parameters
#

while getopts "l:wph" opt
do
        case $opt in
            l) arg_count="${OPTARG}";;
            w) args="--all" ; signals="3";;
            p) pretty="--pretty";;
            h) human="--human";;
            \?) usage ;;
            *) usage ;;
        esac
done

shift `expr ${OPTIND} - 1` ; OPTIND=1

#
#	History of all magnets
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @histlen:=${histlen}; set @signals:='${signals}'; source ${scriptDir}/sql/history.sql;" > "${tmpfile}"


#	Convert to json

python -u ${scriptDir}/csv-to-json.py --file ${tmpfile} --count ${arg_count} ${args} ${pretty} ${human} > ${jsonfile}

#
#	Save data
#

upload_static static/ ${jsonfile} 2> /dev/null
backup_to_static ${jsonfile} 2> /dev/null

#	And return result

cat ${jsonfile}

exit 0

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

[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)
[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)


histlen=30
keep=${1}
keep=${keep:=10}

#
#	History of all magnets
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @histlen:=${histlen}; source ${scriptDir}/sql/history.sql;" > "${tmpfile}"


#	Convert to json

python -u ${scriptDir}/csv-to-json.py --file ${tmpfile} --count  ${keep}  > ${jsonfile}

#
#	Save data
#

upload_static static/ ${jsonfile} 2> /dev/null
backup_to_static ${jsonfile} 2> /dev/null

#	And return result

cat ${jsonfile}

exit 0

#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"



[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

light_id="${1}"
remote_nexa="00D81332"


#
#	Get the current state
#

sql=${scriptDir}/../static/sql/last-switches.sql

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 < ${sql} > ${tmpfile}
awk -v "light_id=${light_id}" -v "remote_nexa=${remote_nexa}" '$4==remote_nexa && $5==light_id  {print $NF}' ${tmpfile}

exit 0

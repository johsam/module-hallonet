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

settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

# Fetch data from rethinkdb and generate crontab entries

{
	${scriptDir}/crongen.py \
	--mailto ${MAILTO} \
	--rethinkdb-host ${RETHINKDB_HOST} \
	--rethink-db ${RETHINKDB_DB} \
	--rethink-table ${RETHINKDB_TABLE} \
	--longitude ${RIPAN_LON} \
	--latitude ${RIPAN_LAT} \
	--altitude ${RIPAN_ALT}
} > ${tmpfile} ; status=$?

# Install new cron file

if [[ ${status} -eq 0 ]] && [[ -s ${tmpfile} ]] ; then
	if [[ "$(uname -n)" == "${RETHINKDB_HOST}" ]] ; then
		cat ${tmpfile}
	else
		cp  ${tmpfile} /etc/cron.d/nexa-from-db
		chmod 644 /etc/cron.d/nexa-from-db
	fi
fi

exit 0

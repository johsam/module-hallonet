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
#	Variables and funtions...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"


[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

#
#	Can we do a backup
#

if [ ! -w "${SQL_BACKUPDIR}" ] ; then
	log "Could not write to '${SQL_BACKUPDIR}' " >> ${SQL_BACKUPLOG}
	exit 1
fi

#
#	Start working
#

now="$(date '+%F_%H-%M')"
rfxname=$(echo ${now} | tr -- ':-' '_')-rfx-dump.sql
tnuname=$(echo ${now} | tr -- ':-' '_')-tnu-dump.sql
nmapname=$(echo ${now} | tr -- ':-' '_')-nmap-dump.sql


(
#
#	Purge old data
#

/home/pi/rfx-commands/scripts/sql-purge.sh

#
#	Dump 'em
#

/usr/bin/mysqldump nmap --single-transaction --quick -urfxuser -prfxuser1 > "${SQL_BACKUPDIR}/${nmapname}"
/usr/bin/mysqldump tnu  --single-transaction --quick -urfxuser -prfxuser1 > "${SQL_BACKUPDIR}/${tnuname}"
/usr/bin/mysqldump rfx  --single-transaction --quick -urfxuser -prfxuser1 > "${SQL_BACKUPDIR}/${rfxname}"


#
#	Zip 'em
#

/bin/gzip -f -q "${SQL_BACKUPDIR}/${nmapname}"
/bin/gzip -f -q "${SQL_BACKUPDIR}/${tnuname}"
/bin/gzip -f -q "${SQL_BACKUPDIR}/${rfxname}"

/bin/gzip -f -q ${SQL_BACKUPDIR}/*.sql 2> /dev/null

#
#	Purge old backups
#

find "${SQL_BACKUPDIR}" -name \*.sql.gz -mtime +3 -exec rm {} \;


) >> ${SQL_BACKUPLOG} 2>&1
exit 0

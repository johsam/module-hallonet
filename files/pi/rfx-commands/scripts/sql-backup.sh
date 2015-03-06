#!/bin/bash

backupDir=/mnt/nas-backup
now="$(date '+%F_%H-%M')"
rfxname=$(echo ${now} | tr -- ':-' '_')-rfx-dump.sql
tnuname=$(echo ${now} | tr -- ':-' '_')-tnu-dump.sql

(
#
#	Purge old data
#

/home/pi/rfx-commands/scripts/sql-purge.sh

#
#	Dump 'em
#

/usr/bin/mysqldump tnu --single-transaction --quick -urfxuser -prfxuser1 > "${backupDir}/${tnuname}"
/usr/bin/mysqldump rfx --single-transaction --quick -urfxuser -prfxuser1 > "${backupDir}/${rfxname}"


#
#	Zip 'em
#

/bin/gzip -f -q "${backupDir}/${tnuname}"
/bin/gzip -f -q "${backupDir}/${rfxname}"

/bin/gzip -f -q ${backupDir}/*.sql 2> /dev/null

#
#	Purge old backups
#

find "${backupDir}" -name \*.sql.gz -mtime +3 -exec rm {} \;
) >> /var/rfxcmd/sqlbackup.log 2>&1
exit 0

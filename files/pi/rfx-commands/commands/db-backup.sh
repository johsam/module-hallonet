
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

[ -h "$0" ] && dir=$(dirname `readlink $0`) || dir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"

settings=${dir}/../settings.cfg
functions=${dir}/../functions.sh

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || (echo "FATAL: Missing '${settings}', Aborting" ; exit 1)
[ -r ${functions} ] && source ${functions} || (echo "FATAL: Missing '${functions}', Aborting" ; exit 1)

# Do it

log "Backup of tnu to /var/rfxcmd/tnu-dump.sql"
mysqldump tnu --single-transaction --quick -urfxuser -prfxuser1 > /var/rfxcmd/tnu-dump.sql
log "Done"

log "Backup of rfx to /var/rfxcmd/sensor-dump.sql"
mysqldump rfx --single-transaction --quick -urfxuser -prfxuser1 > /var/rfxcmd/sensor-dump.sql
log "Done"

exit 0

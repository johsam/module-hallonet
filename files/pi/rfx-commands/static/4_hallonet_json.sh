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

trap 'rm -f "${tmpfile}" "${jsontmpfile}" > /dev/null 2>&1' 0
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


[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
sqlFile=${scriptDir}/sql/temp-nu-avg.sql

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

functions=${scriptDir}/../functions.sh
settings=${scriptDir}/../settings.cfg

# Sanity checks

[ -r ${functions} ] && source ${functions} || { logger -t $(basename $0) "FATAL: Missing '${functions}', Aborting" ; exit 1; }
[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }

displayhours=24
windowsize=15
startofday="1970-01-01"
onlytoday=0

#
#	Parse parameter(s)
#

OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "wlt" _opts
do
	case "${_opts}" in
	l) displayhours=72;;
	w) displayhours=168;windowsize=30;;
	t) startofday="$(date +%F)";onlytoday=1;;
	?) exit 1 ;;
	esac
done

shift `expr $OPTIND - 1` ; OPTIND=1
[ "$1" = "--" ] && shift

#
# If -t is given then ony fetch data for this day
#

[ ${onlytoday} -eq 1 ] && filemiddle="today" || filemiddle=${displayhours}
jsontmpfile="/tmp/tnu-${filemiddle}-ws${windowsize}.json"


#
#	Run the query
#

log "Run sql-query dh=${displayhours} ws=${windowsize}"

mysql tnu -urfxuser -prfxuser1 -A \
	-e "set @startofday='${startofday}',\
	@displayhours:=${displayhours},\
	@windowsize:=${windowsize};\
	source ${sqlFile};" > "${tmpfile}"

#
#	Convert to JSON
#

awk -F'\t' -v "formats=tl"  -f ${scriptDir}/tsv2json-with-formats.awk "${tmpfile}" > "${jsontmpfile}"

#
#	And upload it
#

log "Upload '$(basename ${jsontmpfile})' to webroot"

to_webroot static/graphs ${jsontmpfile}

#
#	Save static
#

to_static ${jsontmpfile}

exit 0


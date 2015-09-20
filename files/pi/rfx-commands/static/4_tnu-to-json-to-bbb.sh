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


#
#	Parse parameter(s)
#

OPTIND=1         # Reset in case getopts has been used previously in the shell.
while getopts "wl" _opts
do
	case "${_opts}" in
	l) displayhours=72;;
	w) displayhours=168;windowsize=30;;
	?) exit 1 ;;
	esac
done
shift `expr $OPTIND - 1` ; OPTIND=1
[ "$1" = "--" ] && shift



jsontmpfile="/tmp/tnu-${displayhours}-ws${windowsize}.json"



#
#	Run the query
#

log "Running query with displayhours=${displayhours} and windowsize=${windowsize}"

mysql tnu \
	-urfxuser -prfxuser1 \
	-A -e "set @displayhours:=${displayhours},@windowsize:=${windowsize} ; source ${sqlFile};" > "${tmpfile}"

#
#	Convert to JSON
#

awk -F'\t' -v "formats=tl"  -f ${scriptDir}/tsv2json-with-formats.awk "${tmpfile}" > "${jsontmpfile}"

#
#	And upload it
#

log "Uploading file '$(basename ${jsontmpfile})' to static webroot"

upload_static static/graphs ${jsontmpfile}

#
#	Save static
#

backup_to_static ${jsontmpfile}

exit 0


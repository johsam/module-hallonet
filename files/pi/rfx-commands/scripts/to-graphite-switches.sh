#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${sqlfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Variables and funtions...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"
sqlfile="/tmp/`basename $0`-$$.sql"
epoch=$(date +%s)

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

sensors=${scriptDir}/../sensors.cfg

# Sanity checks

[ -r ${sensors} ]   && source ${sensors} || { logger -t $(basename $0) "FATAL: Missing '${sensors}', Aborting" ; exit 1; }


#
#	State of all magnets
#

mysql rfx -urfxuser -prfxuser1 \
	-e "set @switches_all:='${switches_magnets}'; source ${scriptDir}/../static/sql/last-switches.sql;" > "${sqlfile}"

#
#	Prepare for graphite
#

awk -v "now=$(date +%s)" 'NR > 1 \
	{\
	gsub(/Off/,"0");\
	gsub(/On/,"1");\
	printf("linux.hallonet.sensors.switches.%s_%s %s %s\n",$4,$5,$7,now)
	}' < "${sqlfile}" > "${tmpfile}"

#	Send it 

nc -q0 mint-black 2003 < "${tmpfile}"


exit 0

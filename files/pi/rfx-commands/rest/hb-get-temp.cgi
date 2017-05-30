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

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
sqlDir="${scriptDir}/../sql"
sql="temperatur-nu.sql"



#	Get outdoor sensor from config file...

source "${scriptDir}/../sensors.cfg"


#	Get Median number from 4 coldest sensors

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_tnu}'; source ${sqlDir}/${sql};" > "${tmpfile}" 2>&1

number="$(head -1 ${tmpfile})"

echo "Content-type: application/json"
echo ""


cat <<-CAT_EOF
{"temperature": ${number}}
CAT_EOF

exit 0

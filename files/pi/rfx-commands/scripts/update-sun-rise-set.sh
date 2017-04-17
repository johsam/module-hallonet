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

export RIPAN_LON RIPAN_LAT RIPAN_ALT

# Now we do it in python instead of perl

python -<< END >> /var/rfxcmd/sun-rise-set.log
import datetime
import astral
import os

today = datetime.date.today()
longitude = float(os.environ['RIPAN_LON'])
latitude = float(os.environ['RIPAN_LAT'])
altitude = float(os.environ['RIPAN_ALT'])

mylocation = astral.Location(info=("Myplace", "Mycountry", latitude, longitude, "Europe/Stockholm", altitude))
mylocation.solar_depression = "civil"

result = mylocation.sun(date=today)

print "{0} {1} {2}".format(
    today.strftime("%Y-%m-%d"),
    result['sunrise'].strftime("%H:%M"),
    result['sunset'].strftime("%H:%M")
)
END

exit 0

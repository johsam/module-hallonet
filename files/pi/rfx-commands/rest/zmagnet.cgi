#!/bin/bash

echo "Content-type: text/plain"
echo ""

# We need som functions here...

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

source ${scriptDir}/cgi.sh


# Get params from QUERY_STRING

declare -A params ; get_query_string params

# Safe defaults

id=${params['id']:=7}
state=${params['state']:=''}
now=${params['now']:=''}

when=$(date "+%F %T"  --date=@${now})
state="$(echo "${state}" | tr '[:upper:]' '[:lower:]')"
state=${state^}

# Run external script

switchId="00123456"
unitcode=${id}
signal=-1

if [ "${state}" == "Off" ] ; then
    dimlevel=0
else
    dimlevel=100
fi


#   Update the database

(
mysql rfx -urfxuser -prfxuser1 <<-SQL_END
INSERT INTO rfxcmd 
(datetime, unixtime, packettype, subtype, seqnbr, battery, rssi, processed, data1, data2, data3, data4,data5, data6, data7, data8, data9, data10, data11, data12, data13)
VALUES ("${when}",${now},'11','00','00',255,${signal},0,"${switchId}",'0',"${state}",${unitcode},${dimlevel},0,0,0.0000,0.0000,0.0000,0.0000,0.0000,'0000-00-00 00:00:00');
SQL_END
) >> /var/rfxcmd/zmagnet-error.log 2>&1

#   Call normal trigger script

/home/pi/rfx-commands/triggers/magnets.sh "${switchId}" "${state}" "${dimlevel}" "${unitcode}" "${signal}"

#   Rescan devices

#if [ "${state}" == "On" ] ; then
#    /home/pi/rfx-commands/scripts/rescan-devices.sh &
#fi

exit 0

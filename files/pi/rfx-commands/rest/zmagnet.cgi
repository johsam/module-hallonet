#!/bin/bash

echo "Content-type: text/plain"
echo ""


#-------------------------------------------------------------------------------
#
#       Function get_query_string
#
#-------------------------------------------------------------------------------

get_query_string() {
  local q="$QUERY_STRING"
  local re1='^(\w+=\w+)&?'
  local re2='^(\w+)=(\w+)$'
  while [[ $q =~ $re1 ]]; do
    q=${q##*${BASH_REMATCH[0]}}
    [[ ${BASH_REMATCH[1]} =~ $re2 ]] && eval "$1+=([${BASH_REMATCH[1]}]=${BASH_REMATCH[2]})"
  done
}

# Get params

declare -A params ; get_query_string params

# Safe defaults

id=${params['id']:=7}
state=${params['state']:=''}
now=${params['now']:=''}

when=$(date "+%F %T"  --date=@${now})
state="$(echo "${state}" | tr '[:upper:]' '[:lower:]')"
state=${state^}

# Run external script

echo "${when} -> ${switchid} -> ${state}" >> /tmp/xxx

switchId="00123456"
unitcode=${id}
signal=7

if [ "${state}" == "Off" ] ; then
    dimlevel=0
else
    dimlevel=100
fi

(
mysql rfx -urfxuser -prfxuser1 <<-SQL_END
INSERT INTO rfxcmd 
(datetime, unixtime, packettype, subtype, seqnbr, battery, rssi, processed, data1, data2, data3, data4,data5, data6, data7, data8, data9, data10, data11, data12, data13)
VALUES ("${when}",${now},'11','00','00',255,${signal},0,"${switchId}",'0',"${state}",${unitcode},${dimlevel},0,0,0.0000,0.0000,0.0000,0.0000,0.0000,'0000-00-00 00:00:00');
SQL_END
) > /tmp/yyy 2>&1

/home/pi/rfx-commands/triggers/magnets.sh "${switchId}" "${state}" "${dimlevel}" "${unitcode}" "${signal}"



exit 0

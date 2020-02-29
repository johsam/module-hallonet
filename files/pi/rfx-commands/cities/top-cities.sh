#!/bin/bash

######################################################################
#
#   Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${hasfile}" "${nearby_xml_file}" "${nearby_json_file}" "${all_xml_file}" "${all_json_file}" "${favourites_xml_file}" "${favourites_json_file}"> /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#   Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
hasfile="/tmp/`basename $0`-$$-has.tmp"

nearby_xml_file="/tmp/nearby.xml"
nearby_json_file="/tmp/nearby.json"

all_xml_file="/tmp/verbose.xml"
all_json_file="/tmp/all.json"

favourites_xml_file="/tmp/favourites.xml"
favourites_json_file="/tmp/favourites.json"

favourites="bergshamra,akersbergac"
count=5

now=$(date '+%F %T')


settings=${scriptDir}/../settings.cfg

source "${BASH_SOURCE%/*}/.env"

# Sanity checks

[ -r ${settings} ]  && source ${settings}  || { logger -t $(basename $0) "FATAL: Missing '${settings}', Aborting" ; exit 1; }


#
#   Parse parameters
#

while getopts "c:" opt
do
        case $opt in
            c) count=$OPTARG;;
            *) exit 0 ;;
        esac
done

shift `expr ${OPTIND} - 1` ; OPTIND=1



NEARBY_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&lat=${RIPAN_LAT}&lon=${RIPAN_LON}&num=$((${count}+1))&verbose"
ALL_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&verbose"
FAVOURITES_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&p=${favourites}&verbose"
HAS_SUN_URL="http://smultronet:8123/api/states/sun.sun"

#	Sunrise/Set

sun_rise=$(awk 'END {print $2}' /var/rfxcmd/sun-rise-set.log)
sun_set=$(awk 'END {print $3}' /var/rfxcmd/sun-rise-set.log)

sun_elevation=0
sun_azimuth=0

curl -s "${NEARBY_URL}" > ${nearby_xml_file}
curl -s "${ALL_URL}" > ${all_xml_file}
curl -s "${FAVOURITES_URL}" > ${favourites_xml_file}
curl -s --connect-timeout 15 --max-time 15 -XGET -H "${AUTH}" -H "Content-Type: application/json" ${HAS_SUN_URL} > ${hasfile} 2> /dev/null


perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${nearby_xml_file}'))" > ${nearby_json_file}
perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${all_xml_file}'))" > ${all_json_file}
perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${favourites_xml_file}'))" > ${favourites_json_file}

python -mjson.tool "${hasfile}" > /dev/null 2>&1; status=$?

if [ ${status} -eq 0 ] ; then
    sun_elevation=$(/usr/local/bin/jq .attributes.elevation < ${hasfile})
    sun_azimuth=$(/usr/local/bin/jq .attributes.azimuth < ${hasfile})
else
    logger -t $(basename $0) "Failed to get data from has"
fi

(
${scriptDir}/top-cities.py \
	--now            "${now}" \
	--nearby         "${nearby_json_file}" \
	--all            "${all_json_file}" \
	--fav            "${favourites_json_file}" \
	--count          "${count}" \
	--sun-rise       "${sun_rise}" \
	--sun-set        "${sun_set}" \
	--sun-elevation  "${sun_elevation}" \
	--sun-azimuth    "${sun_azimuth}"
	
) > ${tmpfile}

#	Is it valid json ?

python -mjson.tool "${tmpfile}" > /dev/null 2>&1; status=$?

if [ ${status} -eq 0 ] ; then
	cat "${tmpfile}"
else
	echo "{\"timestamp\": \"${now}\"}"
fi

exit 0

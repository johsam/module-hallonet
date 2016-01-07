#!/bin/bash

######################################################################
#
#   Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${nearby_xml_file}" "${nearby_json_file}" "${all_xml_file}" "${all_json_file}" "${favourites_xml_file}" "${favourites_json_file}"> /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#   Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"

nearby_xml_file="/tmp/nearby.xml"
nearby_json_file="/tmp/nearby.json"

all_xml_file="/tmp/verbose.xml"
all_json_file="/tmp/all.json"

favourites_xml_file="/tmp/favourites.xml"
favourites_json_file="/tmp/favourites.json"

favourites="bergshamra,akersbergac"
count=5

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



NEARBY_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&lat=59.378617&lon=18.040734&num=$((${count}+1))&verbose"
ALL_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&verbose"
FAVOURITES_URL="http://api.temperatur.nu/tnu_1.15.php?cli=hallonet&p=${favourites}&verbose"

curl -s "${NEARBY_URL}" > ${nearby_xml_file}
curl -s "${ALL_URL}" > ${all_xml_file}
curl -s "${FAVOURITES_URL}" > ${favourites_xml_file}


perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${nearby_xml_file}'))" > ${nearby_json_file}
perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${all_xml_file}'))" > ${all_json_file}
perl -MJSON::Any -MXML::Simple -le "print JSON::Any->new(indent=>1)->objToJson(XMLin('${favourites_xml_file}'))" > ${favourites_json_file}

python ${scriptDir}/top-cities.py --nearby "${nearby_json_file}" --all "${all_json_file}" --fav "${favourites_json_file}" --count ${count}

exit 0

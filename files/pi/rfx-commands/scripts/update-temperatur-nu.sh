#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}"  > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

[ -h "$0" ] && dir=$(dirname `readlink $0`) || dir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"

logfile="/var/rfxcmd/temperatur-nu.log"
curlfile="/var/rfxcmd/temperatur-nu-status.log"
lastokfile="/var/rfxcmd/temperatur-nu-last.log"

sqlDir="${dir}/../sql"
sql="temperatur-nu.sql"


#http://www.temperatur.nu/rapportera.php?hash=443da56c96fc336d3ba366eb9e685f0f&t=

temperaturBaseUrl="http://www.temperatur.nu/rapportera.php"
temperaturHash="443da56c96fc336d3ba366eb9e685f0f"


temperaturUrl="${temperaturBaseUrl}?hash=${temperaturHash}&t="
now="$(date '+%F %T')"

#	Get outdoor sensor from config file...

source "${dir}/../sensors.cfg"

#	Get Average number from sensors

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_outdoor}'; source ${sqlDir}/${sql};" > "${tmpfile}" 2>&1

number="$(cat ${tmpfile})"

#	Is it a real float ?

if [[ "${number}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] ; then

	#	Only 1 decimal to be safe...
	
	tnumber=$(echo "${number}" | awk '{printf("%.1f",$1);}')
	
	#	Report to temperatur.nu
	
	(
	/usr/bin/curl \
		-silent \
		--fail \
		--connect-timeout 15 \
		--max-time        30 \
		--url             "${temperaturUrl}${tnumber}" \
		--output          ${tmpfile}
	) 2>&1 ; curlstatus=$?


	#	Check result
	
	/bin/egrep -q '^ok!\s\(.*\)' ${tmpfile} 2>/dev/null ; grepstatus=$?
	
	#	Save in main log
	
	printf "${now}\t${curlstatus}\t${grepstatus}\t${number}\n" >> ${logfile}

	#	Save in status log
	
	printf "${now} $(cat ${tmpfile} | sed '1,/^\r\{0,1\}$/d')\n" >> "${curlfile}"

	#	Save last successful in file
	
	if [ ${curlstatus} -eq 0 ] && [ ${grepstatus} -eq 0 ] ; then
		printf "${now}\t${number}\n" > ${lastokfile}
	fi

	#	Insert into table tnu
	
	
	/usr/bin/mysql tnu -urfxuser -prfxuser1 -e "insert into tnu values ('${now}',${curlstatus},${grepstatus},${number});"	


	#	Update openhab for graph
	
	curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/T_NU_last --data "${number}"

	
	#	Update openhab data sent to temperatur.nu
	

	last_temperatur_nu=$(awk '{print $2" -> "$3}' "${lastokfile}")
	curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/T_NU_last_info --data "${last_temperatur_nu}"


	# Update openhab min/max info for temperatur.nu
	
	/usr/bin/mysql tnu --skip-column-names -urfxuser -prfxuser1 < ${dir}/../static/sql/temp-nu.sql > "${tmpfile}" 2>&1

 	min_tnu=$(awk -F'\t' '$2 ~ /min/ {print $3}' ${tmpfile})
 	max_tnu=$(awk -F'\t' '$2 ~ /max/ {print $3}' ${tmpfile})

	curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/T_NU_last_min --data "${min_tnu}"
	curl -s --header "Content-Type: text/plain" --request POST  http://localhost:8080/rest/items/T_NU_last_max --data "${max_tnu}"


	#	Update sqlite database

	/home/pi/rfx-commands/scripts/update-sqlite.sh '0000' ${number}

else 
	
	#	Just log n/a in main log
	
	printf "${now}\tn/a\tn/a\tn/a\n" >> ${logfile}
fi



exit 0

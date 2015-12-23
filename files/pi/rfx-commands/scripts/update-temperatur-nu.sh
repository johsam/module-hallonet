#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${statictempfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
statictempfile="/tmp/temperatur.txt"

logfile="/var/rfxcmd/temperatur-nu.log"
curlfile="/var/rfxcmd/temperatur-nu-status.log"
lastokfile="/var/rfxcmd/temperatur-nu-last.log"

sqlDir="${scriptDir}/../sql"
sql="temperatur-nu.sql"


#http://www.temperatur.nu/rapportera.php?hash=443da56c96fc336d3ba366eb9e685f0f&t=

temperaturBaseUrl="http://www.temperatur.nu/rapportera.php"
temperaturHash="443da56c96fc336d3ba366eb9e685f0f"


temperaturUrl="${temperaturBaseUrl}?hash=${temperaturHash}&t="
now="$(date '+%F %T')"

#	Get outdoor sensor from config file...

source "${scriptDir}/../sensors.cfg"

# Get some settings and functions

source "${scriptDir}/../settings.cfg"
source "${scriptDir}/../functions.sh"

#	Get Median number from 4 coldest sensors

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_tnu}'; source ${sqlDir}/${sql};" > "${tmpfile}" 2>&1

number="$(cat ${tmpfile})"

#	Is it a real float ?

if [[ "${number}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] ; then

	#	Save temp for web static
	
	cp ${tmpfile} ${statictempfile}
	upload_static static ${statictempfile}

	
	#	Update graphite

	${scriptDir}/to-graphite-temps.sh '0000' ${number} '00' '0'


	#	Only 1 decimal to be safe...
	
	tnumber=$(echo "${number}" | awk '{printf("%.2f",$1);}')
	
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
	
	to_openhab "Temperatur.nu" "T_NU_last" "${number}" >> ${UPDATE_REST_LOG}

	
	#	Update openhab data sent to temperatur.nu
	

	last_temperatur_nu=$(awk '{print $2" -> "$3}' "${lastokfile}")
	to_openhab "Temperatur.nu" "T_NU_last_info" "${last_temperatur_nu}" >> ${UPDATE_REST_LOG}


	# Update openhab min/max info for temperatur.nu
	
	/usr/bin/mysql tnu --skip-column-names -urfxuser -prfxuser1 < ${scriptDir}/../static/sql/temp-nu.sql > "${tmpfile}" 2>&1

 	min_tnu=$(awk -F'\t' '$2 ~ /min/ {print $3}' ${tmpfile})
 	max_tnu=$(awk -F'\t' '$2 ~ /max/ {print $3}' ${tmpfile})

	to_openhab "Temperatur.nu" "T_NU_last_min" "${min_tnu}" >> ${UPDATE_REST_LOG}
	to_openhab "Temperatur.nu" "T_NU_last_max" "${max_tnu}" >> ${UPDATE_REST_LOG}



else 
	
	#	Just log n/a in main log
	
	printf "${now}\tn/a\tn/a\tn/a\n" >> ${logfile}
fi




#
#	Get Median number from all sensors for tnu
#

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_tnu}'; source ${scriptDir}/../static/sql/median-outdoor.sql;" > "${tmpfile}" 2>&1

number="$(awk '{print $5}' ${tmpfile})"

#	Update graphite

${scriptDir}/to-graphite-temps.sh '0001' ${number} '00' '-1'



exit 0

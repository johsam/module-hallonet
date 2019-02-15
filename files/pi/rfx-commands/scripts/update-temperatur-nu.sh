#!/bin/bash

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" "${statictempfile}" "${sqltempfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15


######################################################################
#
#	Setup variables...
#
######################################################################

[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

tmpfile="/tmp/`basename $0`-$$.tmp"
sqltempfile="/tmp/`basename $0`-$$.sql"
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

#
#   Check if we could write our logs
#

if [ ! -w "/var/rfxcmd" ] ; then
    logger -t $(basename $0) "Directory '/var/rfxcmd' is not writable..."
    exit 1
fi

#	Log it all 

exec >> /var/rfxcmd/update-temperatur-nu-out.log 2>&1 


#	Get outdoor sensor from config file...

source "${scriptDir}/../sensors.cfg"

# Get some settings and functions

source "${scriptDir}/../settings.cfg"
source "${scriptDir}/../functions.sh"

#	Get Median number from 4 coldest sensors

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_tnu}'; source ${sqlDir}/${sql};" > "${sqltempfile}" 2>&1

#number="$(cat ${sqltempfile})"
number="$(head -1 ${sqltempfile})"
tsensors="$(tail -1 ${sqltempfile})"


#	Is it a real float ?

if [[ "${number}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]] ; then
	{
	#	Save temp for web static
	
	echo ${number} > ${statictempfile}
	to_webroot static ${statictempfile}
    	to_static ${statictempfile}
	
	#	Update influxdb and graphite 

	${scriptDir}/to-influx-temps.sh '0000' ${number} '0' '0'
	${scriptDir}/to-graphite-temps.sh '0000' ${number} '00' '0'


	#	Only 2 decimal to be safe...
	
	tnumber=$(echo "${number}" | awk '{printf("%.2f",$1);}')
	
	#	Report to temperatur.nu
	
	(
	/usr/bin/curl \
		-silent \
		--fail \
		--location \
		--connect-timeout 15 \
		--max-time        30 \
		--url             "${temperaturUrl}${tnumber}" \
		--output          "${tmpfile}"
	) 2>&1 ; curlstatus=$?

	#	Check result
	
	/bin/egrep -q '^ok!\s\(.*\)' ${tmpfile} 2>/dev/null ; grepstatus=$?
	
	#	Save in main log
	
	printf "${now}\t${curlstatus}\t${grepstatus}\t${number}\t${tsensors}\n" >> ${logfile}

	#	Save in status log
	
	[ -s "${tmpfile}" ] && printf "${now} $(cat ${tmpfile} | sed '1,/^\r\{0,1\}$/d')\n" >> "${curlfile}"
	[ ! -s "${tmpfile}" ] && printf "${now} failed! (${number})" >> "${curlfile}"

	#	Save last successful in file
	
	if [ ${curlstatus} -eq 0 ] && [ ${grepstatus} -eq 0 ] ; then
		printf "${now}\t${number}\n" > ${lastokfile}
	fi

	#	Insert into table tnu
	
	
	/usr/bin/mysql tnu -urfxuser -prfxuser1 -e "insert into tnu values ('${now}',${curlstatus},${grepstatus},${number},'${tsensors}');"	


	#	Update openhab for graph
	
	to_openhab "T_NU_last" "${number}"

	
	#	Update openhab data sent to temperatur.nu
	

	last_temperatur_nu=$(awk '{print $2" -> "$3}' "${lastokfile}")
	to_openhab "T_NU_last_info" "${last_temperatur_nu}"


	# Update openhab min/max info for temperatur.nu
	
	/usr/bin/mysql tnu --skip-column-names -urfxuser -prfxuser1 < ${scriptDir}/../static/sql/temp-nu.sql > "${tmpfile}" 2>&1

 	min_tnu=$(awk -F'\t' '$2 ~ /min/ {print $3}' ${tmpfile})
 	max_tnu=$(awk -F'\t' '$2 ~ /max/ {print $3}' ${tmpfile})

	to_openhab "T_NU_last_min" "${min_tnu}"
	to_openhab "T_NU_last_max" "${max_tnu}"

	} >> ${UPDATE_REST_LOG}

else 
	
	#	Just log n/a in main log
	
	printf "${now}\tn/a\tn/a\tn/a\tn/a\n" >> ${logfile}
fi




#
#	Get Median number from all sensors for tnu
#

/usr/bin/mysql rfx --skip-column-names -urfxuser -prfxuser1 \
	-e "set @sensors_outdoor='${sensors_tnu}'; source ${scriptDir}/../static/sql/median-outdoor.sql;" > "${tmpfile}" 2>&1

number="$(awk '{print $5}' ${tmpfile})"

#	Update influxdb and graphite

${scriptDir}/to-influx-temps.sh '0001' ${number} '0' '0' >> ${UPDATE_REST_LOG}
${scriptDir}/to-graphite-temps.sh '0001' ${number} '00' '-1' >> ${UPDATE_REST_LOG}



exit 0

#!/bin/bash
exit 0
#
#	echo -e "\u2193"
#

now=$(date +%s)
sensorid=$1
value=$2

db="/var/rfxcmd/sqlite.db"


/usr/bin/sqlite3 "${db}" <<- CAT_EOF
	.timeout 10000
	
	insert into last select * from sensors where sensorid = '${sensorid}';
	insert into sensors values(${now},'${sensorid}',${value});

	-- Update the fake sensor FFFF
	
	insert into last select * from sensors where sensorid = 'FFFF';
	insert into sensors values(
		${now},
		'FFFF',
		(select avg(Temp) from real_rensors_v)
	);

CAT_EOF


exit 0

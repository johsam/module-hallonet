-- Override by -e "set @sensors_all='AAAA,BBBB'; source max-today.sql;"

set @sensors_all := coalesce(@sensors_all,'0000,XXXX');
set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
max(o.datetime) as datetime,
o.packettype    as packettype,
o.data1         as sensorid,
o.data8         as maxtemp

from rfxcmd o 

join 
	(
	select 
	data1,
	max(data8) as max8
	from rfxcmd 

	where unixtime > @unix_today and find_in_set(data1,@sensors_all)
	group by data1
	) as tmax 

on o.data1 = tmax.data1 and o.data8 = tmax.max8

where o.unixtime > @unix_today

group by o.data1;


-- Override by -e "set @sensors_all='AAAA,BBBB'; source min-today.sql;"

set @sensors_all := coalesce(@sensors_all,'0000,XXXX');
set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
min(o.datetime) as datetime,
o.packettype    as packettype,
o.data1         as sensorid,
o.data8         as mintemp

from rfxcmd o 

join 
	(
	select 
	data1,
	min(data8) as min8
	from rfxcmd 

	where unixtime > @unix_today and find_in_set(data1,@sensors_all)
	group by data1
	) as tmin 

on o.data1 = tmin.data1 and o.data8 = tmin.min8

where o.unixtime > @unix_today

group by o.data1;


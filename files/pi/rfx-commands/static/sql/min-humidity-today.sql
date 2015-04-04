-- Override by -e "set @sensors_humidity='AAAA,BBBB'; source min-humidity-today.sql;"

set @sensors_humidity := coalesce(@sensors_humidity,'0000,XXXX');
set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
min(o.datetime) as datetime,
o.packettype    as packettype,
o.data1         as sensorid,
o.data4         as minhumidity

from rfxcmd o

join
	(
	select
	data1,
	min(data4) as min4
	from rfxcmd

	where unixtime > @unix_today and find_in_set(data1,@sensors_humidity)
	group by data1
	) as hmin

on o.data1 = hmin.data1 and o.data4 = hmin.min4

where o.unixtime > @unix_today

group by o.data1;

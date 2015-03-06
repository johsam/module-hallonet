set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data4   as minhumidity

from rfxcmd o 
join 
	(
	select 
	data1,
	min(data4) as min4
	from rfxcmd 
	where unixtime > @unix_today and data1 in ('8700','9700')	
	group by data1
	) as tmin 
on o.data1 = tmin.data1 and o.data4 = tmin.min4

where o.unixtime > @unix_today 

group by o.data1;

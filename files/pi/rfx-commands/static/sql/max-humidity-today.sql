set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data4   as maxhumidity

from rfxcmd o 
join 
	(
	select 
	data1,
	max(data4) as max4
	from rfxcmd 
	where unixtime > @unix_today and data1 in ('8700','9700')	
	group by data1
	) as tmax 
on o.data1 = tmax.data1 and o.data4 = tmax.max4

where o.unixtime > @unix_today 

group by o.data1;

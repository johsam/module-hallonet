set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data8   as maxtemp

from rfxcmd o 
join 
	(
	select 
	data1,
	max(data8) as max8
	from rfxcmd 
	where unixtime > @unix_today and data1 in ('B500','AC00','8700','9700','0700','E400')	
	group by data1
	) as tmax 
on o.data1 = tmax.data1 and o.data8 = tmax.max8

where o.unixtime > @unix_today 

group by o.data1;


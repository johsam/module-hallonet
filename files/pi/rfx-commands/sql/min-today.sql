set @unix_today := UNIX_TIMESTAMP(CURDATE());

select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data8   as mintemp

from rfxcmd o 
join 
	(
	select 
	data1,
	min(data8) as min8
	from rfxcmd 
	where unixtime > @unix_today and data1 in ('B500','AC00','8700','9700','0700')	
	group by data1
	) as tmin 
on o.data1 = tmin.data1 and o.data8 = tmin.min8

where o.unixtime > @unix_today 

group by o.data1;

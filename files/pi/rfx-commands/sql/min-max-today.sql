set @unix_today := UNIX_TIMESTAMP(CURDATE());

-- create index data1_data8 on rfxcmd(data1,data8);
-- drop index data8_data1 on rfxcmd;
-- drop index data1_data8 on rfxcmd;
-- drop index data1_data8 on rfxcmd;
-- create index unixtime on rfxcmd(unixtime);
-- drop index unixtime on rfxcmd;

-- describe

-- show index from rfxcmd;

-- describe

select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data8   as mintemp,
o.data4   as 'humidity',
o.battery as 'battery',
o.rssi    as 'signal'

from rfxcmd o 
join 
	(
	select 
	data1,
	min(data8) as min8
	from rfxcmd 
	where unixtime > @unix_today and data1 in ('B500','AC00','8700','9700','0700','E400')	
	group by data1
	) as tmin 
on o.data1 = tmin.data1 and o.data8 = tmin.min8

where o.unixtime > @unix_today 

group by o.data1;


select 
max(o.datetime) as datetime,
o.packettype,
o.data1   as sensorid,
o.data8   as maxtemp,
o.data4   as 'humidity',
o.battery as 'battery',
o.rssi    as 'signal'

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


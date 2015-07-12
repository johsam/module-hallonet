-- +---------------------+------------+----------+---------+
-- | datetime            | packettype | sensorid | maxtemp |
-- +---------------------+------------+----------+---------+
-- | 2015-07-12 10:30:01 | 50         | FFFF     | 17.1500 |
-- +---------------------+------------+----------+---------+

set @today := CURDATE();

select
	max(t.datetime) as "datetime" ,
	"50"            as "packettype",
	"FFFF"          as "sensorid",
	t.temp          as "maxtemp"
	
	from tnu t 
join 
	(
	select 
	temp,
	max(temp) as maxt
	from tnu 

	where datetime > @today
	) as tmax 

on t.temp = tmax.maxt

where t.datetime > @today;

-- +---------------------+------------+----------+---------+
-- | datetime            | packettype | sensorid | mintemp |
-- +---------------------+------------+----------+---------+
-- | 2015-07-12 05:10:01 | 50         | FFFF     | 13.7000 |
-- +---------------------+------------+----------+---------+

set @today := CURDATE();

select
	min(t.datetime) as "datetime" ,
	"50"            as "packettype",
	"FFFF"          as "sensorid",
	t.temp          as "mintemp"
	
	from tnu t 
join 
	(
	select 
	temp,
	min(temp) as mint
	from tnu 

	where datetime > @today
	) as tmin 

on t.temp = tmin.mint

where t.datetime > @today;

-- +---------------------+------------+----------+-------------+----------+---------+--------+
-- | datetime            | packettype | sensorid | temperature | humidity | battery | signal |
-- +---------------------+------------+----------+-------------+----------+---------+--------+
-- | 2015-07-12 10:20:01 | 50         | 0000     |     17.1000 | 0        | 9       | 9      |
-- +---------------------+------------+----------+-------------+----------+---------+--------+

set @today := CURDATE();
 
select 
	datetime as "datetime",
	"50"     as "packettype",
	"0000"   as "sensorid",
	temp     as "temperature",
	"0"      as "humidity",
	"9"      as "battery",
	"9"      as "signal"
	
	from tnu
	where DATE(datetime) = @today
order by datetime desc limit 1;

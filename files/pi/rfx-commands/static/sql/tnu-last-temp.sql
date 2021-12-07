-- +---------------------+------------+----------+-------------+----------+---------+--------+-----------+
-- | datetime            | packettype | sensorid | temperature | humidity | battery | signal | tnumedian |
-- +---------------------+------------+----------+-------------+----------+---------+--------+-----------+
-- | 2016-02-03 22:50:01 | 50         | 0000     |     -0.8000 | 0        | 9       | 9      | 6900,9300 |
-- +---------------------+------------+----------+-------------+----------+---------+--------+-----------+

set @today := CURDATE();
 
select 
	datetime as "datetime",
	"50"     as "packettype",
	"0000"   as "sensorid",
	temp     as "temperature",
	"0"      as "humidity",
	"9"      as "battery",
	"9"      as "signal",
	sensors  as "tnumedian"
	
	from tnu
	where DATE(datetime) = @today
order by unixtime desc limit 1;

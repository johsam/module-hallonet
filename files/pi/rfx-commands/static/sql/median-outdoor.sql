-- +---------------------+------------+----------+--------+----------+---------+--------+
-- | datetime            | packettype | sensorid | median | humidity | battery | signal |
-- +---------------------+------------+----------+--------+----------+---------+--------+
-- | 2015-07-27 10:20:50 | 50         | 0001     |  15.65 | 0        | 9       | 9      |
-- +---------------------+------------+----------+--------+----------+---------+--------+


-- Override by -e "set @sensors_outdoor='AAAA,BBBB'; source temperatur-nu.sql;"

set @sensors_outdoor := coalesce(@sensors_outdoor,'0000,XXXX');

set @unix_now := UNIX_TIMESTAMP();

create temporary table if not exists tmp_last AS

	select

	i.datetime,
	i.data8 as temperature

	from rfxcmd i
	
	join (
	    select max(unixtime) as mu,
	    data1
	    from rfxcmd
	    group by data1
	) as maxt

	on maxt.data1 = i.data1 and maxt.mu = i.unixtime

	-- Only outdoor sensors and age < 30 min

	where @unix_now - maxt.mu < 1800 and find_in_set(i.data1,@sensors_outdoor) 

	order by temperature ASC
	;

-- 
-- Calculate median from temporary table tmp_last,(https://www.periscope.io/blog/medians-in-sql.html)
-- 

set @ct := (select count(1) from tmp_last);
set @row_id := 0;

select 
	MAX(datetime) as "datetime",
	"50"          as "packettype",
	"0001"        as "sensorid",
	round(avg(temperature),2) as median,
	"0"           as "humidity",
	"9"           as "battery",
	"-1"          as "signal"

from tmp_last
where (select @row_id := @row_id + 1) between @ct/2.0 and @ct/2.0 + 1
;

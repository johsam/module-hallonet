-- +-------------+
-- | temperature |
-- +-------------+
-- |       16.50 |
-- +-------------+

-- Return median of the 4 lowest sensor values

-- Override by -e "set @sensors_outdoor='AAAA,BBBB'; source temperatur-nu.sql;"

set @sensors_outdoor := coalesce(@sensors_outdoor,'0000,XXXX');

set @unix_now := UNIX_TIMESTAMP();

create temporary table if not exists tmp_tnu_last as 
	select distinct

	i.datetime,
	i.data1,
	i.data8 as temperature

	-- At least 15 values the last 30 min

	from rfxcmd i
	join (
	    select max(unixtime) as mu,
	    data1,
	    count(unixtime) as cnt
	    
	    from rfxcmd where @unix_now - unixtime < 1800 
	    group by data1 having cnt >= 5
	) as maxt

	on maxt.data1 = i.data1 and maxt.mu = i.unixtime

	-- Only outdoor sensors

	where find_in_set(i.data1,@sensors_outdoor) 

	order by temperature ASC limit 4
	;

-- 
-- Calculate median from temporary table tmp_tnu_last,(https://www.periscope.io/blog/medians-in-sql.html)
-- 

set @ct := (select count(1) from tmp_tnu_last);
set @row_id := 0;

select round(avg(temperature),2) as temperature

from tmp_tnu_last
where (select @row_id := @row_id + 1) between @ct/2.0 and @ct/2.0 + 1
;

set @row_id := 0;

select group_concat(data1) as sensors

from tmp_tnu_last
where (select @row_id := @row_id + 1) between @ct/2.0 and @ct/2.0 + 1
;


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

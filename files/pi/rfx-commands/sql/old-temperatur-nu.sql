-- Average from min 2 temps

set @unix_now := UNIX_TIMESTAMP();

select round(avg(min2.temperature),2) as temperature from
 	(
	
	-- min 2 temps from all sensors

	select

	i.data8 as temperature
	-- ,i.data1
	-- ,i.datetime
	-- ,i.unixtime
	-- ,@unix_now - maxt.mu

	from rfxcmd i
	
	join (
	    select max(unixtime) as mu,
	    data1
	    from rfxcmd
	    group by data1
	) as maxt

	on maxt.data1 = i.data1 and maxt.mu = i.unixtime

	where i.data1 in ('E400','0700','B500','8700','AC00')
	    and @unix_now - maxt.mu < 3600

	order by temperature ASC limit 2
  	) as min2

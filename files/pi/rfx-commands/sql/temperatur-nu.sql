-- Average from min 2 temps

select round(avg(min2.temperature),2) as temperature from
	(
	
	-- min 2 temps from all sensors

	select

	i.data8 as temperature

	from rfxcmd i
	
	join (
	    select max(unixtime) as mu,
	    data1
	    from rfxcmd
	    group by data1
	) as maxt

	on maxt.data1 = i.data1 and maxt.mu = i.unixtime

	where i.data1 in ('B500','8700','AC00','0700','E400')

	order by temperature ASC limit 2
 	) as min2

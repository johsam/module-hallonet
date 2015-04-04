-- Override by -e "set @sensors_outdoor='AAAA,BBBB'; source temperatur-nu.sql;"

set @sensors_outdoor := coalesce(@sensors_outdoor,'0000,XXXX');

-- Average from min 2 temps

set @unix_now := UNIX_TIMESTAMP();

select round(avg(min2.temperature),2) as temperature from
  	(
	
	-- min 2 temps from all sensors

	select

	i.data8 as temperature
	-- ,i.data1
	-- ,i.datetime
	-- ,@unix_now - maxt.mu

	from rfxcmd i
	
	join (
	    select max(unixtime) as mu,
	    data1
	    from rfxcmd
	    group by data1
	) as maxt

	on maxt.data1 = i.data1 and maxt.mu = i.unixtime

	-- Only outdoor sensors and age < 1 hour

	where @unix_now - maxt.mu < 3600 and find_in_set(i.data1,@sensors_outdoor) 

	order by temperature ASC limit 2
   	) as min2

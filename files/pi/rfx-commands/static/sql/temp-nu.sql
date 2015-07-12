set @today := CURDATE();


select 
	"t_nu",
	"last_info",
	concat(time(datetime)," -> ",format(temp,2))
	from tnu 

order by datetime desc limit 1;

select 
	"t_nu",
	"timestamp",
	datetime
	from tnu 

order by datetime desc limit 1;

select 
	"t_nu",
	"value",
	temp
	from tnu 

order by datetime desc limit 1;



--
-- Min
--

select
	"t_nu",
	"min",
	concat(time(min(t.datetime))," -> ",format(t.temp,2))
	
	from tnu t 
join 
	(
	select 
	temp,
	min(temp) as mint
	from tnu 

	where DATE(datetime) = @today
	) as tmin 

on t.temp = tmin.mint

where DATE(t.datetime) = @today;




--
-- Max
--

select
	"t_nu",
	"max",
	concat(time(max(t.datetime))," -> ",format(t.temp,2))

from tnu t 

join 
	(
	select 
	temp,
	max(temp) as maxt
	from tnu 

	where DATE(datetime) = @today
	) as tmax

on t.temp = tmax.maxt

where DATE(t.datetime) = @today;

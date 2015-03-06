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

set @windowsize := coalesce(@windowsize,15);
set @displayhours := coalesce(@displayhours,24);
set @slew := coalesce(@slew,5);
set @timestart  := DATE_SUB(DATE_SUB(NOW(), INTERVAL @displayhours HOUR),INTERVAL @slew MINUTE);
set @startofday := coalesce(@startofday,"1970-01-01");

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;

select 
	datetime,
	-- UNIX_TIMESTAMP(datetime) as unixtime,
	-- temp as raw,

Round(
(
	SELECT SUM(b.temp) / COUNT(b.temp)
	FROM tnu AS b
	where b.datetime >= @timestart and ( time_to_sec(timediff (b.datetime,a.datetime)) BETWEEN (@windowsize * -60) AND (@windowsize * 60))
),2) AS 'moving_avg'




	from tnu a

where datetime >= GREATEST(@timestart,@startofday)

order by datetime ASC

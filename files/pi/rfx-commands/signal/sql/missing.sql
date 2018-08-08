

set @sensors_all := coalesce(@sensors_all,'3B00,0700,CF00,8700,3D00,A700,B700,9700');
set @days := coalesce(@days,4);


set @unix_start := UNIX_TIMESTAMP(DATE(DATE_ADD(CURDATE(),INTERVAL - @days + 1 DAY)));
set @unix_end   := TRUNCATE(UNIX_TIMESTAMP(NOW()) / 3600,0) * 3600;
set @setcount   := (select LENGTH(@sensors_all) - LENGTH(REPLACE(@sensors_all, ',', '')) + 1);

select 
DATE(datetime) as day,
DATEDIFF(NOW(),datetime) as diff,
DATE_FORMAT(datetime,"%H:00") as start,
DATE_FORMAT(date_add(datetime,INTERVAL 1 HOUR),"%H:00") as end,

group_concat(distinct data1)  as seen

from rfxcmd 
where find_in_set(data1,@sensors_all) and unixtime >= @unix_start and unixtime < @unix_end

group by date(datetime),hour(datetime) 
	having count(distinct(data1)) < @setcount

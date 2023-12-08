

set @sensors_all := coalesce(@sensors_all,'3B00,0700,3600,C700,9300,A700,B700,9700');
set @threshold := coalesce(@threshold,40);
set @days := coalesce(@days,2);


set @unix_start := UNIX_TIMESTAMP(DATE(DATE_ADD(CURDATE(),INTERVAL - @days + 1 DAY)));
set @unix_end   := TRUNCATE(UNIX_TIMESTAMP(NOW()) / 3600,0) * 3600;


select 

DATE(datetime) as day,
DATEDIFF(NOW(),datetime) as diff,
data1 as sensorid,
count(data1) as reports,

DATE_FORMAT(datetime,"%H:00") as start,
DATE_FORMAT(date_add(datetime,INTERVAL 1 HOUR),"%H:00") as end

from rfxcmd 

where find_in_set(data1,@sensors_all) and unixtime >= @unix_start and unixtime < @unix_end
group by data1,date(datetime),hour(datetime) having reports < @threshold  

order by id desc;

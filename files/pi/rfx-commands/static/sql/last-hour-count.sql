-- Round down to nearest hour

set @hour := UNIX_TIMESTAMP(DATE_FORMAT(NOW(), "%Y-%m-%d %H:00:00"));
set @today := UNIX_TIMESTAMP(DATE_FORMAT(NOW(), "%Y-%m-%d 00:00:00"));

select t.sensorid,coalesce(h.hits,0) as hits from


( 

-- Collect all sensors this day

select 
    distinct(data1) as sensorid,
    null
    
    from rfxcmd 
    
    where packettype in (50,52) and unixtime >= @today 
    
) as t

left join

(

-- Count hits the last hour

select 
    data1        as sensorid,
    count(data1) as hits
    
    from rfxcmd 
    
    where packettype in (50,52) and unixtime >= @hour 
    
    group by data1
) as h on t.sensorid = h.sensorid

-- Round down to nearest hour

set @hour := UNIX_TIMESTAMP(DATE_FORMAT(NOW(), "%Y-%m-%d %H:00:00"));

select 
    data1        as sensorid,
    count(data1) as hits
    
    from rfxcmd 
    
    where packettype in (50,52) and unixtime >= @hour 
    
    group by data1;

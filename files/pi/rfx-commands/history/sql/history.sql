set @histlen := coalesce(@histlen,10);
set @signals := coalesce(@signals,"-1,0,1,2,3,4,5,6,7,8,9");
 
SELECT
    datetime,
    unixtime,
    sensorid,
    command,
    rssi  as 'signal'
    -- ,rn,id
FROM
(
    SELECT
        -- id,
	datetime,
	unixtime,
        data3 as command,
        concat(data1,"_",data4) as sensorid,
        rssi,
        @rn := IF(@prev = concat(data1,"_",data4), @rn + 1, 1) AS rn,
        @prev := concat(data1,"_",data4)
    FROM rfxcmd 
 
    JOIN (SELECT @prev := NULL, @rn := 0) AS vars
    WHERE packettype = '11' and data3 in ('On','Off') and find_in_set(rssi,@signals)
    ORDER BY sensorid, id DESC 
) AS T1
WHERE rn <= @histlen
;

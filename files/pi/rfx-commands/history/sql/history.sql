set @histlen := coalesce(@histlen,3);
 
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
    WHERE packettype = '11'
    ORDER BY sensorid, id DESC 
) AS T1
WHERE rn <= @histlen

;

-- select datetime,data1,data3,data4 from rfxcmd where data1 = '0115A1F6' order by datetime desc limit 10

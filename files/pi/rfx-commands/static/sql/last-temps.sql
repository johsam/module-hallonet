-- Override by -e "set @sensors_all='AAAA,BBBB'; source last-temps.sql;"

set @sensors_all := coalesce(@sensors_all,'0000,XXXX');

select
i.datetime,
i.packettype,
i.data1   as 'sensorid',
i.data8   as 'temperature',
i.data4   as 'humidity',
i.battery as 'battery',
i.rssi    as 'signal'

from rfxcmd i
join (
    select
        data1,
        max(unixtime) as mu

    from rfxcmd
    group by data1
    ) as maxt

on maxt.data1 = i.data1 and maxt.mu = i.unixtime

where find_in_set(i.data1,@sensors_all)

order by i.datetime;

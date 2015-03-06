-- describe

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
        max(unixtime) as mu,data1

    from rfxcmd

    group by data1
    ) as maxt

on maxt.data1 = i.data1 and maxt.mu = i.unixtime

where i.data1 in ('B500','AC00','8700','9700','0700')

order by i.datetime;

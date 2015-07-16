-- Override by -e "set @switches_all='AAAA,BBBB'; source last-switches.sql;"

set @switches_all := coalesce(@switches_all,'00CFDEEA,00CFD656,00D81332');


select
i.datetime,
i.packettype,
i.data1   as 'sensorid',
i.data4   as 'subid',
i.rssi    as 'signal',
i.data3   as 'state'

from rfxcmd i
join (
    select
        data1,
        max(unixtime) as mu

    from rfxcmd 
    
    where packettype = '11'
    group by data1,data4
    ) as maxt

on maxt.data1 = i.data1 and maxt.mu = i.unixtime

where find_in_set(i.data1,@switches_all) and i.data3 in ('On','Off')

order by i.datetime;

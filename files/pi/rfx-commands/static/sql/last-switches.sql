-- Override by -e "set @switches_all='AAAA,BBBB'; source last-switches.sql;"

set @switches_all := coalesce(@switches_all,'00D81332,00CFDEEA,00CFD656,00CFDCEE,00EF07E6,0115A1F6,010865CA,0128DCFA');


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
        max(id) as mi

    from rfxcmd 
    
    where packettype = '11'
    group by data1,data4
    ) as maxid

on maxid.data1 = i.data1 and maxid.mi = i.id

where find_in_set(i.data1,@switches_all) and i.data3 in ('On','Off')

order by i.id;

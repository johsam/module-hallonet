select
round(avg(i.data8),2)   as 'temperature'

from rfxcmd i
join (
    select
        max(unixtime) as mu,data1

    from rfxcmd

    group by data1
    ) as maxt

on maxt.data1 = i.data1 and maxt.mu = i.unixtime

where i.data1 in ('B500','8700','0700')


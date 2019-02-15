

create or replace view _last_stamp as
select
    data1 as sensorid,
    max(unixtime) as unixtime

    from rfxcmd
    group by data1;


create or replace view _hour_hits as
select 
    data1        as sensorid,
    count(data1) as hits
    
    from rfxcmd 
    
    where packettype in (50,52) and unixtime >= UNIX_TIMESTAMP(DATE_FORMAT(NOW(), "%Y-%m-%d %H:00:00")) 
    
    group by data1;

create or replace view _last_switch_id as

select
    data1 as sensorid,
    data4 as subid,
    max(id) as maxid

    from rfxcmd 
    
    where packettype = '11'
    group by data1,data4;




create or replace view last_stamp as
    
    select _ls.sensorid,coalesce(s.alias,'???') as alias,s.packettype,_ls.unixtime,FROM_UNIXTIME(_ls.unixtime) as datetime
    from sensors s
    right join _last_stamp as _ls on s.sensorid = _ls.sensorid;
    




create or replace view last_switch_state as
select
    r.datetime,
    r.data1   as 'sensorid',
    r.data4   as 'subid',
    s.alias   as 'alias',
    s.type    as 'type',
    r.rssi    as 'signal',
    r.data3   as 'state'

from rfxcmd r

join _last_switch_id as _lsi on _lsi.sensorid = r.data1 and _lsi.maxid = r.id
join sensors as s on s.sensorid = _lsi.sensorid and s.subid = _lsi.subid
order by r.id;




create or replace view last_temp_sensors as

select
    r.datetime,
    -- r.packettype,
    r.data1              as 'sensorid',
    coalesce(_hh.hits,0) as 'hits',
    s.alias              as 'alias',
    r.data8              as 'temperature',
    case when r.data4 = '0' then ' ' else r.data4 end as 'humidity',
    case when s.outdoor = 1 then 'X' else '' end      as outdoor,
    case when s.tnu = 1 then 'X' else '' end          as tnu,
    r.rssi               as 'signal'

from rfxcmd r
join _last_stamp as _lss on _lss.sensorid = r.data1 and _lss.unixtime = r.unixtime
join sensors as s on s.sensorid = _lss.sensorid and s.packettype in ('50','52')
left join _hour_hits as _hh on _hh.sensorid = s.sensorid
order by s.outdoor,r.id;




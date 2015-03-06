create TABLE 'legend' (
'realsensor' INTEGER,
'sensorid'   TEXT PRIMARY KEY ON CONFLICT REPLACE,
'name'       TEXT
);

create TABLE 'sensors' (
'unixtime' INTEGER,
'sensorid' VARCHAR(4) PRIMARY KEY ON CONFLICT REPLACE,
'temp'     REAL
);

create TABLE 'last' (
'unixtime' INTEGER,
'sensorid' VARCHAR(4) PRIMARY KEY ON CONFLICT REPLACE,
'temp'     REAL
);

drop view current_all_v;

CREATE VIEW current_all_v AS
SELECT 
	l.realsensor as RealSensor,
	s.sensorid as SensorId,
	time(s.unixtime,'unixepoch','localtime') as Time,
	ROUND(o.temp,2) as Previous,
	ROUND(s.temp,2) as Temp,
	case 
		when s.temp > o.temp then "(↑)" 
		when s.temp < o.temp then "(↓)" 
		else "   " 
	end  || " " ||
	l.name as Name
	
FROM sensors s 
inner join legend l on l.sensorid = s.sensorid
left  join last   o on o.sensorid = s.sensorid
;


drop view real_rensors_v;
CREATE VIEW real_rensors_v AS
SELECT 
	s.temp as Temp
	
FROM sensors s 
inner join legend l on l.sensorid = s.sensorid and l.realsensor = 1
;




drop view current_v;
CREATE VIEW current_v AS

select Time,Previous,Temp,Name from current_all_v;



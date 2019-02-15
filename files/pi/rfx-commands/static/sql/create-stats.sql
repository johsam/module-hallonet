DROP TABLE `sensors`;

CREATE TABLE `sensors` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `sensorid` varchar(32) DEFAULT NULL,
  `subid` varchar(12) DEFAULT '00',
  `packettype` varchar(2) DEFAULT NULL,
  `subtype` varchar(2) DEFAULT NULL,
  `alias` varchar(32) DEFAULT NULL,
  `type` varchar(12) DEFAULT '',

  `outdoor` bool DEFAULT NULL,
  `tnu` bool DEFAULT NULL,


  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('00','00','00','rfxtrx433e',false,false);


insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('8700','52','09','Tujan',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('250E','52','07','Tujan (g)',true,false);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('230E','52','07','Tujan (n)',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('B700','50','09','Stuprännan',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('8900','52','07','Stuprännan (v)',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('A700','52','09','Komposten',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('BE01','52','0A','Okänd t/h',true,false);

insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('9700','52','09','Bokhyllan',false,false);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('3902','52','0A','Datorhyllan',false,false);

insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('CF00','50','07','Hammocken Tak',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('3D00','50','07','Hammock Dyna',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('0700','50','07','Förråd Tak',true,true);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('DA00','50','01','Okänd t',true,false);
insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('BE80','50','01','Okänd ?',false,false);

insert into `sensors` (`sensorid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`) values('D800','50','07','Golv TV:n',false,false);


insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00123456','7','00','00','Ytter-dörr',false,false,'door');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00CFDCEE','10','00','00','Grinden',false,false,'door');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00CFDEEA','10','00','00','Altan-dörr',false,false,'door');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00CFD656','10','00','00','Förråds-dörr',false,false,'door');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('0128DCFA','10','00','00','Bokhyllan',false,false,'cabinet');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00EF07E6','10','00','00','Vardagsrum ir',false,false,'ir');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('01519A5E','10','00','00','Förrådet ir',false,false,'ir');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('0253A7F2','16','00','00','Altanen ir',false,false,'ir');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('010865CA','10','00','00','Staketet',false,false,'duskdawn');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','1','00','00','Vid Tv:n',false,false,'light');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','2','00','00','Köksfönstret',false,false,'light');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','3','00','00','Ebbas rum',false,false,'light');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','4','00','00','Julgranen',false,false,'light');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','5','00','00','Hallen',false,false,'light');
insert into `sensors` (`sensorid`,`subid`,`packettype`,`subtype`,`alias`,`outdoor`,`tnu`,`type`) values('00D81332','6','00','00','Ebbas lampa',false,false,'light');


-- select * from `sensors`;

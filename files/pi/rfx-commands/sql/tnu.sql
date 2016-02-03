-- create database tnu;
use tnu;

CREATE TABLE tnu
(
  datetime	DATETIME NOT NULL PRIMARY KEY,
  curl		INT,
  egrep		INT,
  temp		FLOAT(16,4),
  sensors	VARCHAR(32)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;


grant all privileges on tnu.* to rfxuser@localhost;

-- insert into tnu values ('2014-12-31 17:25:02',0,0,4.2,NULL);
-- mysql tnu -urfxuser -prfxuser1 --local-infile -e "load data local infile '/tmp/xxx' into table tnu"

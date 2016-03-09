#!/bin/bash


for l in $(seq 1 10) ; do

mysql rfx -urfxuser -prfxuser1 -e '\
	delete from rfxcmd 
	where unixtime < unix_timestamp(date_sub(CURDATE(),interval 1 month)) 
	order by unixtime asc 
	limit 3000'

sleep 0.5

#mysql rfx -urfxuser -prfxuser1 -e '\
#	select datetime from rfxcmd 
#	where unixtime < unix_timestamp(date_sub(CURDATE(),interval 30 day)) 
#	order by unixtime asc 
#	limit 10'

#mysql rfx -urfxuser -prfxuser1 -e 'select datediff(from_unixtime(min(unixtime)),now()) from rfxcmd;'

#sleep 1
done
 
#mysql rfx -urfxuser -prfxuser1 -e '\
#       select datetime from rfxcmd 
#       where unixtime < unix_timestamp(date_sub(CURDATE(),interval 30 day)) 
#       order by unixtime asc 
#       limit 10'

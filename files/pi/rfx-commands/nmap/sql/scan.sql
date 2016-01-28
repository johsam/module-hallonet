select 
mac,
datetime,
unixtime,
UNIX_TIMESTAMP(NOW()) - unixtime as age,
ip

from nmap 
order by datetime desc,ipdec asc;

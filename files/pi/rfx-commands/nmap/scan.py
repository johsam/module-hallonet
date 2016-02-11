import nmap
import time
import datetime
import socket
import struct
import json

from peewee import *

database = MySQLDatabase('nmap', **{'password': 'rfxuser1', 'user': 'rfxuser'})


class BaseModel(Model):
    class Meta:
        database = database


class Nmap(BaseModel):
    datetime = DateTimeField(null=False)
    unixtime = IntegerField(null=False)
    mac = CharField(primary_key=True, null=False)
    ip = CharField(null=False)
    ipdec = BigIntegerField(null=False)
    hostname = CharField(null=False)

    class Meta:
        db_table = 'nmap'


def ip2long(ip):
    return struct.unpack("!L", socket.inet_aton(ip))[0]


def do_scan(cfg):
    result = nm.scan(hosts='192.168.1.0/24', arguments=cfg)

    for ip, entry in result['scan'].iteritems():
	if len(entry['hostnames']) == 0:
	    hostname = entry['vendor'].itervalues().next()
	else:
	    hostname = entry['hostnames'][0]['name']
	
	if 'mac' in entry['addresses']:
            mac = entry['addresses']['mac']
            ipdec = ip2long(ip)

            new_nmap = {'datetime': stamp, 'unixtime': epoch_time, 'mac': mac, 'ip': ip, 'ipdec': ipdec, 'hostname': hostname}
            # Update or insert new record

            existing_nmap, created = Nmap.get_or_create(mac=new_nmap['mac'], defaults=new_nmap)
	    if created is False:
        	for key in new_nmap:
                    setattr(existing_nmap, key, new_nmap[key])
                    existing_nmap.save()



database.create_tables([Nmap], safe=True)


epoch_time = int(time.time())
stamp = datetime.datetime.fromtimestamp(epoch_time).strftime('%F %H:%M:00')

nm = nmap.PortScanner()

do_scan("-sn -T5")
do_scan("-sn -T4")
do_scan("-sn")

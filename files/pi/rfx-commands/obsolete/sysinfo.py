#!/usr/bin/python

import re
import argparse
import httplib
import time
from datetime import timedelta

headers = {"Content-type": "text/plain"}

def send(url,data):
	
	try:
		print "{0}={1}".format(url,data)
		conn = httplib.HTTPConnection(args.openhab + ":8080")
		conn.request('POST', url, data,headers)
		

	except:
		print("No connection to openhab on http://" + args.openhab)


#
# Parse arguments
#

parser = argparse.ArgumentParser(description='Rest import of data to openhab')

parser.add_argument(
	'--openhab', required=False,
	default='localhost',
	dest='openhab',
	help='Openhab host'
)

args = parser.parse_args()

#
# Uptime
#

with open('/proc/uptime', 'r') as f:
    uptime_seconds = float(f.readline().split()[0])
    uptime_string = str(timedelta(seconds = uptime_seconds))

# Loose the sub second part
uptime_string = re.sub(r"\..*","",uptime_string)

#
# Load average
#

with open('/proc/loadavg', 'r') as f:
    lavg = f.readline().split()

load_avg = "{0}  {1}  {2}".format(lavg[0],lavg[1],lavg[2])

#
# Update openhab
#

send("/rest/items/PI_uptime",uptime_string)
time.sleep(0.5)
send("/rest/items/PI_loadavg",load_avg)

exit(0)

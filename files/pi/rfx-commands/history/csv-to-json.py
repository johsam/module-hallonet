# coding=iso-8859-1

import csv
import argparse
import json
import time
from datetime import timedelta


#
# Parse arguments
#
parser = argparse.ArgumentParser(description='SQL results to json')

parser.add_argument(
	'--file', required=True,
	default='',
	dest='file',
	help='File containing history values'
)

parser.add_argument(
	'--count', required=True,
	default=10,
	type=int,
	dest='count',
	help='FMax number of last items to keep'
)


args = parser.parse_args()

history = {}
result = {}
lastcommand = {}
epoch_time = int(time.time())
stamp = epoch_time


#
# Read file and save data
#

with open(args.file, 'rb') as csvfile:

	sqlData = csv.DictReader(csvfile, dialect="excel-tab")

	for row in sqlData:

		datetime = row['datetime']
		unixtime = int(row['unixtime'])
		sensorid = row['sensorid']
		command = row['command']
		signal = int(row['signal'])

		if sensorid not in history:
			history[sensorid] = {'last' : []}
			lastcommand[sensorid] = '?'
			stamp = epoch_time
		
		# Only keep count items, result set from sql is larger than we want to keep
		
		if len(history[sensorid]['last']) >= args.count:
			continue
			
		# Only keep this if state has changed, Swithes sometimes bounses a bit giving duplicates
		
		duration = stamp - unixtime
		delta = str(timedelta(seconds=duration))
		
		if command != lastcommand[sensorid] and duration > 1:
			history[sensorid]['last'].append({'duration': duration, 'delta': delta, 'datetime': datetime, 'unixtime': unixtime, 'command': command, 'signal': signal})
			lastcommand[sensorid] = command
			stamp = unixtime
		#else:
		#	history[sensorid]['last'].append({'dup': True,'datetime': datetime, 'command': command, 'signal': signal})
	
result['type'] = 'history'
result['history'] = history

		
print json.dumps(result, indent=4, sort_keys=True)

# coding=iso-8859-1

import csv
import argparse
import json
import time
import re
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
	help='Max number of last items to keep'
)

parser.add_argument(
	'--all', required=False,
	dest='all',
	action='store_true',
	help='Show all'
)

parser.add_argument(
	'--pretty', required=False,
	dest='pretty',
	action='store_true',
	help='Pretty json'
)



parser.set_defaults(all=False)
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
		
		if args.all or (command != lastcommand[sensorid] and duration > 1):
			history[sensorid]['last'].append({'dlt': delta,'cmd': command, 'sig': signal, 'ut': unixtime,})
			lastcommand[sensorid] = command
			stamp = unixtime
	
result['type'] = 'history'
result['history'] = history

if args.pretty:		
	print json.dumps(result, indent=2, sort_keys=True)
else:
	print json.dumps(result, sort_keys=True, separators=(',', ':'))

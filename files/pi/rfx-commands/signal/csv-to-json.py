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
	help='File containing signal values'
)

parser.add_argument(
	'--sensors', required=True,
	default='',
	dest='sensors',
	help='File containing sensor values'
)


args = parser.parse_args()

signal = {}
result = {}

aliases = {}
locations = {}

#
# Read sensors.json to get all sensor aliases
#

with open(args.sensors) as data_file:
	sensor_data = json.load(data_file)


for s in sensor_data['sensors']:
	aliases[s['id']] = s['alias']
	locations[s['id']] = s['location']
	
#
# Read file and save data
#

with open(args.file, 'rb') as csvfile:

	sqlData = csv.DictReader(csvfile, dialect="excel-tab")
	
	for row in sqlData:
		key = row['diff']
		day = row['day']
		sensorid = row['sensorid']
		reports = int(row['reports'])
		start = row['start']
		end = row['end']
		
		if key not in signal:
			signal[key] = {'day': day,'sensors': {}}
		if sensorid not in signal[key]['sensors']:
			signal[key]['sensors'][sensorid] = {'alias': aliases[sensorid],'location':locations[sensorid], 'missed':[]}

		signal[key]['sensors'][sensorid]['missed'].append({'reports':reports,'start':start,'end':end})
		
result['type'] = 'signal'
result['signal'] = signal

		
print json.dumps(result, indent=2, sort_keys=True)
#print json.dumps(result, sort_keys=True, separators=(',', ':'))

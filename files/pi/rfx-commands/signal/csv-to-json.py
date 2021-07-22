#!/usr/bin/env python
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

parser.add_argument(
    '--missing', required=False,
    default='',
    dest='missing',
    help='File containing missing sensor values'
)


parser.add_argument(
    '--all', required=True,
    default='',
    dest='all',
    help='File containing all valid sensors'
)


#
# Parse arguments
#

args = parser.parse_args()

signal = {}
result = {}

aliases = {}
locations = {}

all_sensors = args.all.split(',')

#
# Read sensors.json to get all sensor aliases
#

with open(args.sensors) as data_file:
    sensor_data = json.load(data_file)


for s in sensor_data['sensors']:
    aliases[s['id']] = s['alias']
    locations[s['id']] = s['location']


def add2signal(key, day, sensorid, start, end, reports):
    try:
      if key not in signal:
          signal[key] = {'day': day, 'sensors': {}}
      if sensorid not in signal[key]['sensors']:
          signal[key]['sensors'][sensorid] = {'alias': aliases[sensorid], 'location': locations[sensorid], 'missed': []}

      signal[key]['sensors'][sensorid]['missed'].append({'reports': reports, 'start': start, 'end': end})
      signal[key]['sensors'][sensorid]['missed'] = sorted(signal[key]['sensors'][sensorid]['missed'], key=lambda k: k['start'], reverse = True) 
    except Exception:
       pass
#
# Read file containing some missed values
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

        add2signal(key, day, sensorid, start, end, reports)

#
# Read file containing complete missing sensors
#

if args.missing:
    with open(args.missing, 'rb') as csvfile:

        sqlData = csv.DictReader(csvfile, dialect="excel-tab")

        for row in sqlData:
            key = row['diff']
            day = row['day']
            start = row['start']
            end = row['end']
            seen = row['seen'].split(',')

            try:
	    	for sensorid in all_sensors:
                    if sensorid not in seen:
                    	add2signal(key, day, sensorid, start, end, 0)
    	    except:
	    	pass

result['type'] = 'signal'
result['signal'] = signal


print json.dumps(result, indent=2, sort_keys=True)
#print json.dumps(result, sort_keys=True, separators=(',', ':'))

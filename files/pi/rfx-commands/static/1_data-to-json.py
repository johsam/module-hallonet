# coding=iso-8859-1
import csv
import argparse
import json
from datetime import *
from dateutil.relativedelta import *
from dateutil.parser import *

#
# Parse arguments
#
parser = argparse.ArgumentParser(description='SQL results to json')

parser.add_argument(
	'--last-file', required=True,
	default='',
	dest='last_file',
	help='File containing last values'
)

parser.add_argument(
	'--min-file', required=True,
	default='',
	dest='min_file',
	help='File containing min values'
)

parser.add_argument(
	'--max-file', required=True,
	default='',
	dest='max_file',
	help='File containing max values'
)


parser.add_argument(
	'--min-hum-file', required=True,
	default='',
	dest='hum_min_file',
	help='File containing min values'
)


parser.add_argument(
	'--max-hum-file', required=True,
	default='',
	dest='hum_max_file',
	help='File containing max values'
)

parser.add_argument(
	'--system-file', required=True,
	default='',
	dest='system_file',
	help='File containing system values'
)


args = parser.parse_args()

sensorData = {}
sensorAliases = {

	"E400": {
		"alias": "Anna:s",
		"location": "outside",
		"order": 0
	},

	"0700": {
		"alias": "Förrådet",
		"location": "outside",
		"order": 1
	},

	"B500": {
		"alias": "Hammocken",
		"location":
		"outside",
		"order": 2
	},

	"8700": {
		"alias": "Tujan",
		"location": "outside",
		"order": 3
	},

	"AC00": {
		"alias": "Cyklarna",
		"location":"outside",
		"order": 4
	},

	"9700": {
		"alias": "Bokhyllan",
		"location": "inside",
		"order": 5
	}

}

result = {'success': True, 'sensors': []}
now = datetime.now()


#
# Read file and save data
#

def readFile(filename, section, colname, dictkey):
	with open(filename, 'rb') as csvfile:

		sqlData = csv.DictReader(csvfile, dialect="excel-tab")

		for row in sqlData:

			sensorid = row['sensorid']
			colvalue = row[colname]
			datetime = row['datetime']

			if sensorid not in sensorData:
				sensorData[sensorid] = {'sensorid': sensorid}

			if section not in sensorData[sensorid]:
				sensorData[sensorid][section] = {}

			sensorData[sensorid][section][dictkey]['value'] = float(colvalue)
			sensorData[sensorid][section][dictkey]['timestamp'] = datetime


#
# Read systemfile
#

def readSystemFile(filename):
	with open(filename, 'rb') as csvfile:

		sqlData = csv.DictReader(csvfile, dialect="excel-tab")

		for row in sqlData:

			section = row['section']
			key = row['key']
			value = row['value']

			if section not in result:
				result[section] = {}
			result[section][key] = value.decode('iso8859-1')
			


#
# Read last data
#

with open(args.last_file, 'rb') as csvfile:

	sqlData = csv.DictReader(csvfile, dialect="excel-tab")

	for row in sqlData:

		sensorid = row['sensorid']
		temperature = row['temperature']
		humidity = row['humidity']
		sensortype = row['packettype']
		datetime = row['datetime']
		alias = 'n/a'
		location = 'n/a'
		order = 0

		if sensorid not in sensorData:
			sensorData[sensorid] = {}

		if sensorid in sensorAliases:
			alias = sensorAliases[sensorid]['alias']
			location = sensorAliases[sensorid]['location']
			order = sensorAliases[sensorid]['order']

		# Check if datetime is stale
		
		delta=relativedelta(now,parse(datetime))
		if delta.days > 0 or delta.hours > 0 or delta.minutes > 30:
			alias = alias + " ???"

		sensorData[sensorid]['order'] = order
		sensorData[sensorid]['sensor'] = {
			'alias': alias,
			'id': sensorid,
			'type' : int(sensortype),
			'location' : location
		}

		sensorData[sensorid]['temperature'] = {'min': {}, 'max': {}, 'last': {}}
		sensorData[sensorid]['temperature']['last']['value'] = float(temperature)
		sensorData[sensorid]['temperature']['last']['timestamp'] = datetime

		sensorData[sensorid]['temperature']['min']['value'] = float(temperature)
		sensorData[sensorid]['temperature']['min']['timestamp'] = datetime

		sensorData[sensorid]['temperature']['max']['value'] = float(temperature)
		sensorData[sensorid]['temperature']['max']['timestamp'] = datetime
		
		
		if int(sensortype) == 52:
			sensorData[sensorid]['humidity'] = {'min': {}, 'max': {}, 'last': {}}
			sensorData[sensorid]['humidity']['last']['value'] = float(humidity)
			sensorData[sensorid]['humidity']['last']['timestamp'] = datetime

			sensorData[sensorid]['humidity']['min']['value'] = float(humidity)
			sensorData[sensorid]['humidity']['min']['timestamp'] = datetime

			sensorData[sensorid]['humidity']['max']['value'] = float(humidity)
			sensorData[sensorid]['humidity']['max']['timestamp'] = datetime
		

#
# Read min temps
#

readFile(args.min_file, 'temperature', 'mintemp', 'min')


#
# Read max temps
#

readFile(args.max_file, 'temperature', 'maxtemp', 'max')


#
# Read min humidity
#

readFile(args.hum_min_file, 'humidity', 'minhumidity', 'min')


#
# Read max humidity
#

readFile(args.hum_max_file,'humidity', 'maxhumidity', 'max')


readSystemFile(args.system_file)




#
# Collect all data and output json...
#



for sensorid in sensorData:
	result['sensors'].append(sensorData[sensorid])


result['sensors'] = sorted(result['sensors'], key=lambda k: k['order']) 


# print json.dumps(sensorData, indent=4, sort_keys=True)
print json.dumps(result, indent=4, sort_keys=True, encoding="utf-8")

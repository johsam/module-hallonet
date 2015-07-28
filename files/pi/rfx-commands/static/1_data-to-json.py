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

parser.add_argument(
	'--switch-file', required=True,
	default='',
	dest='switch_file',
	help='File containing switch values'
)

args = parser.parse_args()


switchData = {}
switchAliases = {

	"00D81332_1": {
		"alias": "Vid Tv:n",
		"type":  "light",
		"order": 1
	},
	"00D81332_2": {
		"alias": "Köksfönstret",
		"type":  "light",
		"order": 2
	},
	"00D81332_3": {
		"alias": "Ebbas rum",
		"type":  "light",
		"order": 3
	},
	"00D81332_4": {
		"alias": "Julgranen",
		"type":  "light",
		"order": 4
	},
	
	
	"03D242AA_16": {
		"alias": "Ytterdörren",
		"type":  "magnet",
		"order": -5
	},
	"00CFDEEA_10": {
		"alias": "Altanen",
		"type":  "magnet",
		"order": -4
	},
	"00CFD656_10": {
		"alias": "Förrådet",
		"type":  "magnet",
		"order": -3
	}

}



sensorData = {}
sensorAliases = {
	
	# Not real sensors

	"0000": {
		"alias": "Temperatur.nu",
		"location": "outside",
		"order": -100
	},

	"0001": {
		"alias": "Median (*)",
		"location": "outside",
		"order": 100
	},


	# Outside sensors

	"3B00": {
		"alias": "Anna:s",
		"location": "outside",
		"order": 0
	},

	"0700": {
		"alias": "Förrådets Tak",
		"location": "outside",
		"order": 1
	},

	"B700": {
		"alias": "Förrådets Golv",
		"location": "outside",
		"order": 2
	},

	"7500": {
		"alias": "Hammocken",
		"location": "outside",
		"order": 3
	},

	"8700": {
		"alias": "Tujan",
		"location": "outside",
		"order": 4
	},

	"A700": {
		"alias": "Komposten",
		"location":"outside",
		"order": 5
	},

	"AC00": {
		"alias": "Cyklarna",
		"location":"outside",
		"order": 6
	},
	
	# Inside sensors

	"9700": {
		"alias": "Bokhyllan",
		"location": "inside",
		"order": 7
	}

}

result = {'success': True, 'sensors': [],'switches': []}
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

			if dictkey not in sensorData[sensorid][section]:
				sensorData[sensorid][section][dictkey] = {}

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
# Read switch file
#

with open(args.switch_file, 'rb') as csvfile:
	sqlData = csv.DictReader(csvfile, dialect="excel-tab")

	for row in sqlData:
		sensorid = row['sensorid'] + '_' + row['subid']
		timestamp = row['datetime']
		state = row['state']
		alias = 'n/a'
		swtype = 'n/a'
		order = 0
		

		if sensorid not in switchData:
			switchData[sensorid] = {}

		if sensorid in switchAliases:
			alias = switchAliases[sensorid]['alias']
			swtype = switchAliases[sensorid]['type']
			order = switchAliases[sensorid]['order']

		switchData[sensorid]['id'] = sensorid
		switchData[sensorid]['alias'] = alias
		switchData[sensorid]['order'] = order
		switchData[sensorid]['type'] = swtype
		switchData[sensorid]['timestamp'] = timestamp
		switchData[sensorid]['state'] = state

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

for sensorid in switchData:
	result['switches'].append(switchData[sensorid])


for sensorid in sensorData:
	result['sensors'].append(sensorData[sensorid])


result['switches'] = sorted(result['switches'], key=lambda k: k['order']) 
result['sensors'] = sorted(result['sensors'], key=lambda k: k['order']) 


# print json.dumps(sensorData, indent=4, sort_keys=True)
print json.dumps(result, indent=4, sort_keys=True, encoding="utf-8")

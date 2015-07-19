#!/usr/bin/env python
# coding=iso-8859-1
import argparse
import json
from pubnub import Pubnub

from dateutil.parser import *

#
# Parse arguments
#

parser = argparse.ArgumentParser(description='JSON to rest')

parser.add_argument(
	'--file', required=True,
	default='',
	dest='file',
	help='File containing json'
)

parser.add_argument(
	'--sensor-id', required=False,
	default='',
	dest='sensor_id',
	help='Sensor id'
)

parser.add_argument(
	'--sensor-value', required=False,
	default='',
	dest='sensor_value',
	help='Sensor value'
)


parser.add_argument(
	'--sensor-humidity', required=False,
	default='',
	dest='sensor_humidity',
	help='Sensor humidity'
)

parser.add_argument(
	'--switch-id', required=False,
	default='',
	dest='switch_id',
	help='Switch id'
)

parser.add_argument(
	'--switch-state', required=False,
	default='',
	dest='switch_state',
	help='Switch state'
)



parser.add_argument(
	'--stamp', required=False,
	default='',
	dest='stamp',
	help='Sensor timestamp'
)

# Pubnub

parser.add_argument(
	'--pubnub-subkey', required=True,
	default='',
	dest='pubnub_subkey',
	help='Pubnub subscribe key'
)


parser.add_argument(
	'--pubnub-pubkey', required=True,
	default='',
	dest='pubnub_pubkey',
	help='Pubnub publish key'
)

parser.add_argument(
	'--pubnub-channel', required=True,
	default='',
	dest='pubnub_channel',
	help='Pubnub channel'
)



args = parser.parse_args()


def publish_sensor(s):
	ps = {}
	ps['type'] = 'sensor'
	ps['sensor'] = s

	#pubnub.publish(args.pubnub_channel, ps)


def publish_switch(s):
	ps = {}
	ps['type'] = 'switch'
	ps['switch'] = s

	pubnub.publish(args.pubnub_channel, ps)


def processSensors(a,id,value,humidity,stamp):
	
	for i in a:
		sensorid = i['sensor']['id']
		if sensorid == id:
			i['temperature']['last']['timestamp'] = stamp
			i['temperature']['last']['value'] = float(value)
			
			if float(value) >= float(i['temperature']['max']['value']):
				i['temperature']['max']['value'] = float(value)
				i['temperature']['max']['timestamp'] = stamp			
			
			if float(value) <= float(i['temperature']['min']['value']):
				i['temperature']['min']['value'] = float(value)
				i['temperature']['min']['timestamp'] = stamp			

			if 'humidity' in i and humidity != '':
				i['humidity']['last']['timestamp'] = stamp
				i['humidity']['last']['value'] = float(humidity)
			
			
			publish_sensor(i)
			break


def processSwitches(a,id,state,stamp):
	for i in a:
		swid = i['id']
		if swid == id:
			i['timestamp'] = stamp
			i['state'] = state
			publish_switch(i)
			break


#
# main starts here
#

pubnub = Pubnub(publish_key=args.pubnub_pubkey,
                    subscribe_key=args.pubnub_subkey,
                    secret_key='',
                    cipher_key='',
                    ssl_on=False
)



with open(args.file) as data_file:
	json_data = json.load(data_file)

	if args.sensor_id != '':
		if 'sensors' in json_data:
			processSensors(json_data['sensors'],args.sensor_id,args.sensor_value,args.sensor_humidity,args.stamp)

	if args.switch_id != '':
		if 'switches' in json_data:
			processSwitches(json_data['switches'],args.switch_id,args.switch_state,args.stamp)


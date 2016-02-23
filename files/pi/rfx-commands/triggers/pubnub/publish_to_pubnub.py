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

parser.add_argument(
    '--signal', required=False,
    type=int,
    default=0,
    dest='signal',
    help='Sensor signal'
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

parser.add_argument(
	'--refresh', required=False,
	dest='refresh',
	action='store_true',
	help='Send refresh'
)

args = parser.parse_args()


def publish_sensor(s):
    ps = {}
    ps['type'] = 'sensor'
    ps['sensor'] = s

    pubnub.publish(args.pubnub_channel, ps)


def publish_switch(s):
    ps = {}
    ps['type'] = 'switch'
    ps['switch'] = s
    
    pubnub.publish(args.pubnub_channel, ps)


def publish_refresh():
    ps = {}
    ps['type'] = 'refresh'
    pubnub.publish(args.pubnub_channel, ps)


def processSensors(a, id, value, humidity, stamp, signal):

    for i, item in enumerate(a):
        sensorid = a[i]['id']
        if sensorid == id:
            a[i]['signal'] = signal

            a[i]['temperature']['last']['timestamp'] = stamp
            a[i]['temperature']['last']['value'] = float(value)

            if float(value) >= float(a[i]['temperature']['max']['value']):
                a[i]['temperature']['max']['value'] = float(value)
                a[i]['temperature']['max']['timestamp'] = stamp

            if float(value) <= float(a[i]['temperature']['min']['value']):
                a[i]['temperature']['min']['value'] = float(value)
                a[i]['temperature']['min']['timestamp'] = stamp

            # Humidity

            if 'humidity' in a[i] and humidity != '':
                a[i]['humidity']['last']['timestamp'] = stamp
                a[i]['humidity']['last']['value'] = float(humidity)

                if float(humidity) >= float(a[i]['humidity']['max']['value']):
                    a[i]['humidity']['max']['value'] = float(humidity)
                    a[i]['humidity']['max']['timestamp'] = stamp

                if float(humidity) <= float(a[i]['humidity']['min']['value']):
                    a[i]['humidity']['min']['value'] = float(humidity)
                    a[i]['humidity']['min']['timestamp'] = stamp

            publish_sensor(a[i])
            break


def processSwitches(a, id, state, stamp, signal):
    for i, item in enumerate(a):
	swid = a[i]['id']
        if swid == id:
            a[i]['timestamp'] = stamp
            a[i]['state'] = state
            a[i]['signal'] = signal
            publish_switch(a[i])
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
    try:
        json_data = json.load(data_file)
    except:
        pass

    if args.sensor_id != '':
        if 'sensors' in json_data:
            processSensors(json_data['sensors'], args.sensor_id, args.sensor_value, args.sensor_humidity, args.stamp, args.signal)
            print json.dumps(json_data,indent=2, sort_keys=True, encoding="utf-8") 

    if args.switch_id != '':
        if 'switches' in json_data:
            processSwitches(json_data['switches'], args.switch_id, args.switch_state, args.stamp, args.signal)
            print json.dumps(json_data,indent=2, sort_keys=True, encoding="utf-8") 

    if args.refresh == True:
    	publish_refresh()

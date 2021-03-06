#!/usr/bin/env python
# coding=iso-8859-1
import argparse
import json
import syslog

import sys
sys.exit(0)

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

parser.add_argument(
    '--message', required=False,
    default='',
    dest='message',
    help='Message to Hallonet'
)

parser.add_argument(
    '--notify', required=False,
    dest='notify',
    action='store_true',
    help='Send notify'
)

parser.add_argument(
    '--devices', required=False,
    default='',
    dest='devices',
    help='Devices to Hallonet'
)

args = parser.parse_args()


def callback(message):
    syslog.syslog("Error: Got-> " + str(message))


def publish_main(c,o):
    pubnub.publish(c, o, error=callback)


def log_publish(t,i,l=None):
    if l is not None:
    	syslog.syslog("Channel '{0}': type:'{1}' info:'{2}' level:'{3}'".format(args.pubnub_channel, t, i,l))
    else:
    	syslog.syslog("Channel '{0}': type:'{1}' info:'{2}'".format(args.pubnub_channel, t, i))


def publish_sensor(s):
    ps = {}
    ps['type'] = 'sensor'
    ps['sensor'] = s
    publish_main(args.pubnub_channel, ps)
    #log_publish(ps['type'],s)


def publish_switch(s):
    ps = {}
    ps['type'] = 'switch'
    ps['switch'] = s
    publish_main(args.pubnub_channel, ps)
    if 'subtype' in s:
        log_publish(ps['type'],"{0}:{1}->{2}".format(s['alias'].encode('utf-8'), s['subtype'].encode('utf-8'), s['state'].encode('utf-8')))
    elif 'type' in s:
        log_publish(ps['type'],"{0}:{1}->{2}".format(s['alias'].encode('utf-8'), s['type'].encode('utf-8'), s['state'].encode('utf-8')))
    else:
        log_publish(ps['type'],"{0}:->{1}".format(s['alias'].encode('utf-8'), s['state'].encode('utf-8')))


def publish_refresh():
    ps = {}
    ps['type'] = 'refresh'
    ps['target'] = 'sensors'
    publish_main(args.pubnub_channel, ps)
    log_publish(ps['type'],ps['target'])


def publish_message(msg = ''):
    ps = {}
    ps['type'] = 'message'
    ps['message'] = msg
    ps['level'] = 'toast'

    if len(msg):
        publish_main(args.pubnub_channel, ps)
        log_publish(ps['type'],msg)


def publish_notify(msg = ''):
    ps = {}
    ps['type'] = 'message'
    ps['message'] = msg
    ps['level'] = 'notify'
    
    if len(msg):
        publish_main(args.pubnub_channel, ps)
        log_publish(ps['type'],msg,ps['level'])


def publish_devices(d,dl):
    ps = {}
    ps['type'] = 'devices'
    ps['devices'] = d

    publish_main(args.pubnub_channel, ps)
    log_publish(ps['type'],dl)



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

def processDevices(a,dev_ids):
    result = []
    dl = dev_ids.split(',')
    for d in a:
	if d['id'] in dl:
	    result.append(d)
    
    publish_devices(result,dev_ids)
	

#
# main starts here
#

pubnub = Pubnub(publish_key=args.pubnub_pubkey,
                subscribe_key=args.pubnub_subkey,
                secret_key='',
                cipher_key='',
                ssl_on=False
                )

syslog.openlog(facility=syslog.LOG_DAEMON)


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
            print json.dumps(json_data, indent=2, sort_keys=True, encoding="utf-8") 

    if args.refresh is True:
        publish_refresh()
 
    if len(args.message):
    	if args.notify is True:
            publish_notify(args.message)
    	else:   
            publish_message(args.message)

    if args.devices != '':
    	if 'devices' in json_data:
	    processDevices(json_data['devices'],args.devices)
 

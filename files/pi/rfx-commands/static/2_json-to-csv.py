#!/usr/bin/env python 
# coding=iso-8859-1

import argparse
import json
import re
from dateutil.parser import *
from datetime import datetime

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

args = parser.parse_args()


def nicedate(d,p='i'):
    parsed = parse(d)

    daydiff=datetime.today().day - parsed.day

    if daydiff == 0:
    	stamp = parsed.strftime("%T")

    elif daydiff == 1:
    	stamp = parsed.strftime("%T")
	stamp = p + u' g\u00E5r '+stamp

    else:
    	stamp = parsed.strftime("%d/%m %T")
    	stamp = re.sub(r"\/0","/",stamp)

    return stamp


def processSwitches(a):
	for i in a:

		switchtype = i['type']
	
		if switchtype == 'magnet':
			
			switchalias = i['alias']
			switchtype = i['subtype']
						
			switchid = i['id']
			switchstate = i['state']
			switchstamp = i['timestamp']
			
			stamp = nicedate(switchstamp)
			
			if switchstate == "On":
    	    	    	    if switchtype == "ir":
			    	status='Aktiv'
			    else:
    			    	status=u'\u00D6ppen'
			else:
    	    	    	    if switchtype == "ir":
			    	status='Passiv'
			    else:
				status=u'St\u00E4ngd'
						
			status = status.encode('ascii','xmlcharrefreplace')
			stamp = stamp.encode('ascii','xmlcharrefreplace')
			
			print "M_" + switchid + "\t" + status + " " + stamp


def processSensors(a):
	
	def tp(t,st,si,v,ts):
		d,s = ts.split();	# We only want the time
		print "T_" + str(st) + "_" + si + "_" + t + "\t" + str(v)
		print "T_" + str(st) + "_" + si + "_" + t + "_stamp\t" + str(s)
		

	def th(t,st,si,v,ts):
		d,s = ts.split();	# We only want the time
		print "H_" + str(st) + "_" + si + "_" + t + "\t" + str(v)
		print "H_" + str(st) + "_" + si + "_" + t + "_stamp\t" + str(s)


	for i in a:

		sensorid = i['id']
		sensortype = i['type']
		
		# Skip fake sensor Temperatur.nu
		
		if sensorid == '0000':
			continue
		
		for t in ['last','min','max']:
			value = i['temperature'][t]['value']
			timestamp = i['temperature'][t]['timestamp']

			tp(t,sensortype,sensorid,value,timestamp)
		

		if int(sensortype) == 52:

			for t in ['last']:
				value = i['humidity'][t]['value']
				timestamp = i['humidity'][t]['timestamp']

				th(t,sensortype,sensorid,value,timestamp)



def processSection(b,s):
	if s in json_data[b]:
		for a in json_data[b][s]:
						
			value = a['value']
			
			if 'type' in a:
			    if a['type'] == 'date':
			    	value = nicedate(value,'I')
			
			value = value.encode('ascii','xmlcharrefreplace')
			key = re.sub(r"^{0}_".format(s),s.upper() + "_",a['section_key'])
			
			print key + "\t" + value


with open(args.file) as data_file:
	json_data = json.load(data_file)

    	print "item\tvalue"

	if 'switches' in json_data:
		processSwitches(json_data['switches'])

	if 'sensors' in json_data:
		processSensors(json_data['sensors'])

	processSection('system', 'pi')
	processSection('system', 'openhab')
	processSection('system', 'sql')
	processSection('system', 'has')
	processSection('system', 'static')
	processSection('system', 'misc')


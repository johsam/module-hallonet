# coding=iso-8859-1
import argparse
import json
import re
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

args = parser.parse_args()



def processSection(s):
	if s in json_data:
		for key, value in json_data[s].iteritems():
			
			#value = value.decode('utf-8')
			#value = value.encode('raw_unicode_escape').decode('utf-8').encode('utf-8')
			#value = value.encode('raw_unicode_escape')
			
			value = value.encode('ascii','xmlcharrefreplace')
			
			print s.upper() + "_" + key + "\t" + value

def processSwitches(a):
	for i in a:

		switchtype = i['type']
	
		if switchtype == 'magnet':
			
			switchalias = i['alias']
						
			switchid = i['id']
			switchstate = i['state']
			switchstamp = i['timestamp']
			
			parsed = parse(switchstamp)
			stamp = parsed.strftime("%d/%m %T")
			stamp = re.sub(r"\/0","/",stamp)
			
			status=u'\u00D6ppen'
			
			if switchstate == "Off":
				status=u'St\u00E4ngd'
			
			status = status.encode('ascii','xmlcharrefreplace')

			
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


print "item\tvalue"

with open(args.file) as data_file:
	json_data = json.load(data_file)

	if 'sensors' in json_data:
		processSensors(json_data['sensors'])

	if 'switches' in json_data:
		processSwitches(json_data['switches'])

	processSection('pi')
	processSection('static')
	processSection('sql')


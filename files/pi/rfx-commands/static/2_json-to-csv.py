# coding=utf-8
import argparse
import json

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


def processSensors(a):
	
	def tp(t,st,si,v,ts):
		d,s = ts.split();	# We on ly want the time
		print "T_" + str(st) + "_" + si + "_" + t + "\t" + str(v)
		print "T_" + str(st) + "_" + si + "_" + t + "_stamp\t" + str(s)
		

	def th(t,st,si,v,ts):
		d,s = ts.split();	# We on ly want the time
		print "H_" + str(st) + "_" + si + "_" + t + "\t" + str(v)
		print "H_" + str(st) + "_" + si + "_" + t + "_stamp\t" + str(s)


	for i in a:

		sensorid = i['sensor']['id']
		sensortype = i['sensor']['type']
		
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

	processSection('pi')
	processSection('static')
	processSection('sql')


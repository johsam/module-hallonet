import csv
import httplib
import time
import datetime
import argparse


inputCsv = "/tmp/last.csv"

headers = {"Content-type": "text/plain"}


def send(url,data,timestamp):
	s = datetime.datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
	timestamp = s.strftime("%H:%M:%S")
	
	try:
		print "{0}={1}".format(url,data)
		conn = httplib.HTTPConnection(args.openhab + ":8080")
		conn.request('POST', url, data,headers)
		
		time.sleep(0.2)

		print "{0}={1}".format(url + "_stamp",timestamp)
		conn = httplib.HTTPConnection(args.openhab + ":8080")
		conn.request('POST', url + "_stamp", timestamp,headers)

	except:
		print("No connection to openhab on http://" + args.openhab)

#
# Parse arguments
#
parser = argparse.ArgumentParser(description='Rest import of data to openhab')

parser.add_argument(
	'--file', required=True,
	default='',
	dest='csv_file',
	help='File to write to'
)

parser.add_argument(
	'--openhab', required=False,
	default='localhost',
	dest='openhab',
	help='Openhab host'
)

args = parser.parse_args()

#
# Read and post
#

with open(args.csv_file, 'rb') as csvfile:
	
	sqlData = csv.DictReader(csvfile, dialect="excel-tab")
	
	for row in sqlData:
		
		dataType="last"
		data = 0
		
		if row['packettype'] == '50' or row['packettype'] == '52' :
			
			if 'temperature' in row:
				data = row['temperature']
				dataType = "last"
			if 'mintemp' in row:
				data = row['mintemp']
				dataType = "min"
			if 'maxtemp' in row:
				data = row['maxtemp']
				dataType = "max"

			url = "/rest/items/T_{0}_{1}_{2}".format(row['packettype'],row['sensorid'],dataType)
			send(url,data,row['datetime'])

	
			
		if row['packettype'] == '52':

			if 'humidity' in row:
				data = row['humidity']
				dataType = "last"
				url = "/rest/items/H_{0}_{1}_{2}".format(row['packettype'],row['sensorid'],dataType)
				send(url,data,row['datetime'])
		
		time.sleep(0.2)

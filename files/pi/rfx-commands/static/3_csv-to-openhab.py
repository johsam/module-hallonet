#!/usr/bin/env python
# coding=iso-8859-1

import sys
import csv
import argparse
import HTMLParser
import httplib
import time

#
# Parse arguments
#

parser = argparse.ArgumentParser(description='JSON to rest')

parser.add_argument(
	'--file', required=True,
	default='',
	dest='file',
	help='File containing csv rest data'
)

args = parser.parse_args()


#
# Start the work...
#

htmlparser = HTMLParser.HTMLParser()
headers = {"Content-type": "text/plain"}


with open(args.file, 'rb') as csvfile:

	data = csv.DictReader(csvfile, dialect="excel-tab")

	for row in data:

		item = row['item']
		value = htmlparser.unescape(row['value']).encode('utf-8')
		
		#print time.strftime("%Y-%m-%d %H:%M:%S") + " " + str(item) +" -> " + value
		
		conn = httplib.HTTPConnection("localhost:8080")
		conn.request('POST', "/rest/items/" + item, value, headers)
		time.sleep(0.5)


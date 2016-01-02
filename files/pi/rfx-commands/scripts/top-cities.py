#!/usr/bin/env python
# -*- coding: iso-8859-1 -*-

import json
import re
import argparse
import urllib2
from BeautifulSoup import BeautifulSoup

DEGC = u'\u00B0' + 'C'
URL = 'http://www.temperatur.nu/livesearch.php?string=&order=temperatur&sortorder=fallande'
URL = 'http://www.temperatur.nu/matplatser.html'

dataset = []
seen = {}
cities = {'warmest': [], 'coldest': []}


def r_enumerate(container):
    i = len(container)
    for item in reversed(container):
        i = i - 1
        yield i, item

#
# Parse arguments
#

parser = argparse.ArgumentParser(description='Scrape list of temperatures')

parser.add_argument(
    '--count', required=False,
    default=5,
    type=int,
    dest='count',
    help='Number of cold/warm cities'
)
args = parser.parse_args()

#
# Process html
#

try:
    html = urllib2.urlopen(URL).read()
    soup = BeautifulSoup(html, convertEntities=BeautifulSoup.HTML_ENTITIES)
    stadlistcontainer = soup.find("table", attrs={"id": "stadlistcontainer"})

    for row in stadlistcontainer.findAll("tr"):

        city = row.find("td", attrs={"class": "stadlist"}).findAll(text=True)[0]
        if city in seen:
            continue

        seen[city] = True

        temp = row.find("td", attrs={"class": "stadtemp"}).findAll(text=True)[0]
        temp = re.sub(DEGC, '', temp)
        temp = re.sub(',', '.', temp)

        if temp != "N/A":
            dataset.append({'city': city, 'temp': float(temp)})

    newlist = sorted(dataset, key=lambda k: (k['temp'], k['city']))

    #
    #   Append warmest cities
    #

    order = 1
    for idx, val in r_enumerate(newlist):
        cities['warmest'].append({'city': val['city'], 'temp': val['temp'], 'section_key': 'warm_' + str(order)})
        order += 1
        if idx <= len(newlist) - args.count:
            break

    #
    #   Append coldest cities
    #

    order = 1
    for idx, val in enumerate(newlist, start=1):
        cities['coldest'].append({'city': val['city'], 'temp': val['temp'], 'section_key': 'cold_' + str(order)})
        order += 1
        if idx >= args.count:
            break
except:
    pass

print json.dumps(cities, indent=2)

exit(0)

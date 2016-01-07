#!/usr/bin/env python

import json
import re
import argparse


def cleanup_city(city, kommun):
    city = re.sub('_', ' ', city)
    city = re.sub(kommun, '', city)
    city = re.sub('Sthlm', '', city)
    city = re.sub('^/|/$', '', city)

    if (len(city)):
        city = kommun + ' - ' + city
    else:
        city = kommun

    return city


def collect_cities(i, seen={}):
    dataset = []

    for key, val in i.iteritems():
        city = val['title']
        kommun = val['kommun']
        temp = val['temp']

        if city in seen:
            continue

        seen[city] = True
        city = cleanup_city(city, kommun)

        if temp != "N/A":
            dataset.append({
                'kommun': kommun,
                'city': city,
                'temp': float(temp)
            })

    return sorted(dataset, key=lambda k: (k['temp'], k['city']))


def insert_cities(l, section):
    for idx, val in enumerate(l, start=1):
        cities[section].append({
            'kommun': val['kommun'],
            'city': val['city'],
            'temp': val['temp'],
            'section_key': section + '_' + str(idx)
            }
        )

        if idx >= args.count:
            break


#
# Parse arguments
#

parser = argparse.ArgumentParser(description='Convert list of temperatures')

parser.add_argument(
    '--nearby', required=False,
    default='',
    dest='nearby',
    help='Nearby cities'
)

parser.add_argument(
    '--all', required=False,
    default='',
    dest='all',
    help='All cities'
)

parser.add_argument(
    '--fav', required=False,
    default='',
    dest='fav',
    help='Favourites cities'
)


parser.add_argument(
    '--count', required=False,
    default=5,
    type=int,
    dest='count',
    help='Number of cities'
)

args = parser.parse_args()

#
# Start to work
#

cities = {'warmest': [], 'coldest': [], 'nearby': [], 'favourites': []}

all_json = json.loads(open(args.all).read(), 'utf8')
items = all_json['channel']['item']
citylist = collect_cities(items, seen={})

#   Append coldest cities

insert_cities(citylist, 'coldest')

#   Append warmest cities

citylist = sorted(citylist, key=lambda k: (k['temp'], k['city']), reverse=True)
insert_cities(citylist, 'warmest')


#
# Nearby
#

nearby_json = json.loads(open(args.nearby).read(), 'utf8')
items = nearby_json['channel']['item']

# Skip ourselves
citylist = collect_cities(items, seen={"Sthlm/Bergshamra": True})
insert_cities(citylist, 'nearby')


#
# Favourites
#

if args.fav:
    favourites_json = json.loads(open(args.fav).read(), 'utf8')
    items = favourites_json['channel']['item']

    # We need at least 2 cities to get an array, Skip ourselves
    citylist = collect_cities(items, seen={"Sthlm/Bergshamra": True})
    insert_cities(citylist, 'favourites')


print json.dumps(cities, indent=2)

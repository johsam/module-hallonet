# coding=iso-8859-1
import csv
import argparse
import json
from datetime import *
from dateutil.relativedelta import *
from dateutil.parser import *
from babel.dates import format_timedelta

#
# Parse arguments
#
parser = argparse.ArgumentParser(description='SQL results to json')

parser.add_argument(
    '--last-file', required=True,
    default='',
    dest='last_file',
    help='File containing last values'
)

parser.add_argument(
    '--min-file', required=True,
    default='',
    dest='min_file',
    help='File containing min values'
)

parser.add_argument(
    '--max-file', required=True,
    default='',
    dest='max_file',
    help='File containing max values'
)


parser.add_argument(
    '--min-hum-file', required=True,
    default='',
    dest='hum_min_file',
    help='File containing min values'
)


parser.add_argument(
    '--max-hum-file', required=True,
    default='',
    dest='hum_max_file',
    help='File containing max values'
)

parser.add_argument(
    '--system-file', required=True,
    default='',
    dest='system_file',
    help='File containing system values'
)

parser.add_argument(
    '--switch-file', required=True,
    default='',
    dest='switch_file',
    help='File containing switch values'
)

parser.add_argument(
    '--cities-file', required=False,
    default='',
    dest='cities_file',
    help='File containing cities values'
)

parser.add_argument(
    '--tnu-sensors', required=True,
    default='',
    dest='tnu_sensors',
    help='Comma separated string with tnu sensors'
)

parser.add_argument(
    '--devices-file', required=True,
    default='',
    dest='devices_file',
    help='Csv file'
)

parser.add_argument(
    '--macs', required=True,
    default='',
    dest='macs',
    help='Mac mappings'
)

parser.add_argument(
    '--missing', required=False,
    default='',
    dest='missing_file',
    help='Missing sensor count for today'
)

parser.add_argument(
    '--hits-file', required=True,
    default='',
    dest='hits_file',
    help='Csv file'
)


parser.add_argument(
	'--device-max-age', required=False,
	default=3600 * 24 * 30,
	type=int,
	dest='device_max_age',
	help='Max age in seconds for devices'
)


parser.add_argument(
	'--tnu-history-file', required=False,
	dest='tnu_history_file',
	help='JSON array of last unique values to Temperatur.nu'
)


args = parser.parse_args()


switchData = {}
sensorData = {}


systemAliases = {

    # pi

    "pi_core_temp": {
        "alias": "Cpu Temp",
        "order": 1
    },
    "pi_loadavg": {
        "alias": "Cpu Medel",
        "order": 2
    },
    "pi_uptime": {
        "alias": "Upptid",
        "order": 3
    },
    "pi_updates": {
        "alias": "Uppdateringar",
        "order": 4,
	"type": "hilite_non_zero"
    },
    "pi_last_boot": {
        "alias": "Bootad",
        "order": 5,
        "type": "date"
    },
    "pi_wifi_restart": {
        "alias": "Wifi Omstart",
        "order": 6,
        "type": "date"
    },
    "pi_wifi_link": {
        "alias": u"Wifi L\u00e4nk",
        "order": 7,
    },
    "pi_wifi_level": {
        "alias": u"Wifi Niv\u00e5",
        "order": 8,
    },
    "pi_public_ip": {
        "alias": "Publik Ip",
        "order": 9
    },

    # smultronet

    "pib_core_temp": {
        "alias": "Cpu Temp",
        "order": 1
    },
    "pib_loadavg": {
        "alias": "Cpu Medel",
        "order": 2
    },
    "pib_uptime": {
        "alias": "Upptid",
        "order": 3
    },
    "pib_updates": {
        "alias": "Uppdateringar",
        "order": 4,
	"type": "hilite_non_zero"
    },
     "pib_last_boot": {
        "alias": "Bootad",
        "order": 5,
        "type": "date"
    },


    # openhab

    "openhab_status": {
        "alias": "Status",
        "order": 1,
    },
    "openhab_load": {
        "alias": "Cpu",
        "order": 2
    },
    "openhab_restarted": {
        "alias": "Startad",
        "order": 3,
        "type": "date"
    },

    # home-assistant

    "has_started": {
        "alias": "Startad",
        "order": 1,
        "type": "date"
    },
    "has_status": {
        "alias": "Status",
        "order": 2
    },
    "has_version": {
        "alias": "Version",
        "order": 3
    },


    # YR.no "//api.met.no/weatherapi/weathericon/1.1/?symbol=3;content_type=image/png"

    "yr_sensor.yr_cloudiness": {
        "alias": "Molnighet",
        "order": 1
    },

    "yr_sensor.yr_pressure": {
        "alias": "Lufttryck",
        "order": 2
    },

    "yr_sensor.yr_condition": {
        "alias": "Regn",
        "order": 3
    },

    "yr_sensor.yr_wind_direction": {
        "alias": "Vindriktning",
        "order": 4
    },

    "yr_sensor.yr_wind_speed": {
        "alias": "Vindstyrka",
        "order": 5
    },

    "yr_sensor.yr_symbol_not_yet": {
        "alias": "Symbol",
        "order": 6
    },


    # Mint black

    "mintblack_core_temp": {
        "alias": "Cpu Temp",
        "order": 1
    },
    "mintblack_loadavg": {
        "alias": "Cpu Medel",
        "order": 2
    },
    "mintblack_uptime": {
        "alias": "Upptid",
        "order": 3
    },
    "mintblack_updates": {
        "alias": "Uppdateringar",
        "order": 4,
	"type": "hilite_non_zero"
    },
    "mintblack_last_boot": {
        "alias": "Bootad",
        "order": 5,
        "type": "date"
    },


    # Misc

    "misc_rfxcmd_last_restart": {
        "alias": "Rfxcmd Startad",
        "order": 1,
        "type": "date"
    },
    
    "misc_pubnubmgr_last_restart": {
        "alias": "Pubnubmgr Startad",
        "order": 2,
        "type": "date"
    },

    # static

    "static_timestamp": {
        "alias": "Senaste data",
        "order": 1,
        "type": "date"
    },

    "sql_timestamp": {
        "alias": "Senaste sql",
        "order": 1,
        "type": "date"
    }


}

switchAliases = {

    "00D81332_1": {
        "alias": "Vid Tv:n",
        "type":  "light",
        "nexaid": 1,
        "fab": True,
        "order": 1
    },
    "00D81332_2": {
        "alias": u"K\u00f6ksf\u00f6nstret",
        "type":  "light",
        "nexaid": 2,
        "fab": True,
        "order": 2
    },
    "00D81332_3": {
        "alias": "Ebbas rum",
        "type":  "light",
        "nexaid": 3,
        "fab": True,
        "order": 3
    },
    "00D81332_5": {
        "alias": "Hallen",
        "type":  "light",
        "nexaid": 5,
        "fab": True,
        "order": 4
    },
    "00D81332_4": {
        "alias": "Julgranen",
        "type":  "light",
        "nexaid": 4,
        "fab": False,
        "order": 5
    },
    "00123456_7": {
        "alias":   u"Ytterd\u00F6rren (Z)",
        "type":    "magnet",
        "subtype": "door",
	"badge":   True,
        "order":   -11
    },
    "00CFDEEA_10": {
        "alias":   "Altanen",
        "type":    "magnet",
        "subtype": "door",
	"badge":   True,
        "order":   -10
    },
    "00CFD656_10": {
        "alias":   u"F\u00f6rr\u00e5det",
        "type":    "magnet",
        "subtype": "door",
        "order":   -9
    },
    "0128ED32_10": {
        "alias":   "Grinden",
        "type":    "magnet",
        "subtype": "door",
	"badge":   True,
	"divider": True,
        "order":   -8
    },
    "032C96AA_16": {
        "alias":   "Bokhyllan (*)",
        "type":    "magnet",
        "subtype": "door",
        "order":   -7
    },
    "00CFDCEE_10": {
        "alias":   "Badrummet",
        "type":    "magnet",
        "subtype": "door",
        "nowarn":  True,
        "order":   -6
    },
    "00EF07E6_10": {
        "alias":   "Vardagsrum",
        "type":    "magnet",
        "subtype": "ir",
        "order":   -5
    },
    "0115A1F6_10": {
        "alias":   "Altanen",
        "type":    "magnet",
        "subtype": "ir",
        "order":   -4
    },
    "010865CA_10": {
        "alias":   "Staketet (*)",
        "type":    "magnet",
        "subtype": "duskdawn",
        "order":   -3
    }

}


sensorAliases = {

    # Not real sensors

    "0000": {
        "alias": "Temperatur.nu",
        "location": "outside",
        "order": -100
    },

    "0001": {
        "alias": "Median (*)",
        "location": "outside",
        "order": 100
    },


    # Outside sensors

    "3B00": {
        "alias": "Anna:s",
        "location": "outside",
        "order": 0
    },

    "0700": {
        "alias": u"F\u00f6rr\u00e5d Tak",
        "location": "outside",
        "order": 1
    },


    "CF00": {
        "alias": "Hammocken",
        "location": "outside",
        "order": 2
    },

    "8700": {
        "alias": "Tujan",
        "location": "outside",
        "order": 3
    },

    "B700": {
        "alias": u"Stupr\u00e4nnan",
        "location": "outside",
        "order": 4
    },

    "A700": {
        "alias":    "Komposten",
        "location": "outside",
        "order": 5
    },

    "AC00": {
        "alias":    "Cyklarna",
        "location": "outside",
        "order": 6
    },

    "8900": {
        "alias":    u"Stupr\u00e4nnan (v)",
        "location": "outside",
        "order": 7
    },
  
    # Inside sensors

    "9700": {
        "alias": "Bokhyllan",
        "location": "inside",
        "order": 8
    }

}


deviceAliases = {
    "1": {
        "alias": "Johans Galaxy S6",
        "order": 1,
	"hilite": True
    },
    "2": {
        "alias": "Johans Samsung",
        "order": 2
    },

    "3": {
        "alias": "Catarinas iPhone 6",
        "order": 3,
	"hilite": True
    },

    "4": {
        "alias": "Catarinas iPad",
        "order": 4
    },

    "5": {
        "alias": "Catarinas Surface",
        "order": 5
    },

    "6": {
        "alias": "Ebbas iPhone",
        "order": 6
    },


    "12": {
        "alias": "Ebbas iPhone 6",
        "order": 7,
	"hilite": True
    },

    "7": {
        "alias": "Ebbas Air",
        "order": 8
    },

    "8": {
        "alias": "Ebbas iPad",
        "order": 9
    },

    "9": {
        "alias": "Ebbas Surface",
        "order": 10
    },

    "10": {
        "alias": "Sony Android TV",
        "dividerabove": True,
	"order": 11
    },
    
    "13": {
        "alias": "Edup Wifi Socket",
        "order": 13
    },

    "14": {
        "alias": "Johans Lenovo",
        "order": 14
    }

}

result = {'success': True, 'hoursmissingcount': 0, 'sensors': [], 'switches': [], 'devices': [], 'lasthour': [], 'tnu_trend': [], 'toplist': {'coldest': [], 'warmest': []}}
now = datetime.now()
tnu_sensors = args.tnu_sensors.split(',')

#
# Collect coldest/warmest outside sensors
#

def toplist(r):

    for s in r['sensors']:
        if s['location'] == 'outside':
            alias = s['alias']
            id = s['id']

            if id == '0001':
                continue

            timestamp = s['temperature']['max']['timestamp']
            value = s['temperature']['max']['value']
            r['toplist']['warmest'].append({
                'alias': alias,
                'id': id,
                'timestamp': timestamp,
                'value': value
            })

            timestamp = s['temperature']['min']['timestamp']
            value = s['temperature']['min']['value']
            r['toplist']['coldest'].append({
                'alias': alias,
                'id': id,
                'timestamp': timestamp,
                'value': value
            })


#
# Read file and save data
#

def readFile(filename, section, colname, dictkey):
    with open(filename, 'rb') as csvfile:

        sqlData = csv.DictReader(csvfile, dialect="excel-tab")

        for row in sqlData:

            sensorid = row['sensorid']
            colvalue = row[colname]
            datetime = row['datetime']

            if sensorid not in sensorData:
                sensorData[sensorid] = {'sensorid': sensorid}

            if section not in sensorData[sensorid]:
                sensorData[sensorid][section] = {}

            if dictkey not in sensorData[sensorid][section]:
                sensorData[sensorid][section][dictkey] = {}

            sensorData[sensorid][section][dictkey]['value'] = float(colvalue)
            sensorData[sensorid][section][dictkey]['timestamp'] = datetime


#
# Read citiesfile
#

def readCitiesFile(filename):
    with open(filename) as data_file:
    	data = json.load(data_file)
    	result['cities'] = data

#
# Read trend file
#

def readTrendFile(filename):
    with open(filename) as data_file:
    	data = json.load(data_file)
    	result['tnu_trend'] = data


#
# Read missingfile
#

def readMissingFile(filename):
    counter = 0
    with open(filename) as data_file:
            data = json.load(data_file)
            signals = data['signal']
	    
	    if '0' in signals:
		for k,v in signals['0']['sensors'].items():
		    #counter += len(v['missed'])	    
		    counter += 1	    

    return counter

#
# Read systemfile
#

def readSystemFile(filename):
    with open(filename, 'rb') as csvfile:

        sqlData = csv.DictReader(csvfile, dialect="excel-tab")

        for row in sqlData:

            section = row['section']
            key = row['key']
            value = row['value']

            section_key = section + "_" + key
            if section_key not in systemAliases:
                continue

            alias = systemAliases[section_key]['alias']
            order = systemAliases[section_key]['order']
            infotype = "string"
            if 'type' in systemAliases[section_key]:
                infotype = systemAliases[section_key]['type']

            # Values are now in utf-8
	    # value = value.decode('iso8859-1')

            if "system" not in result:
                result["system"] = {}

            if section not in result["system"]:
                result["system"][section] = []

            result["system"][section].append({"alias": alias, "section_key": section_key, "value": value, "order": order, "type": infotype})


#
#   Read hits file
#

with open(args.hits_file, 'rb') as csvfile:
    sqlData = csv.DictReader(csvfile, dialect="excel-tab")
    
    for row in sqlData:
        sensorid = row['sensorid']
        count = int(row['hits'])

	if sensorid in sensorAliases:
            alias = sensorAliases[sensorid]['alias']
            order = sensorAliases[sensorid]['order']
	    result["lasthour"].append({'alias': alias, 'id': sensorid, 'count': count, 'order': order})
 



#
# Read switch file
#

with open(args.switch_file, 'rb') as csvfile:
    sqlData = csv.DictReader(csvfile, dialect="excel-tab")

    for row in sqlData:
        sensorid = row['sensorid'] + '_' + row['subid']
        timestamp = row['datetime']
        state = row['state']
        signal = int(row['signal'])
        alias = 'n/a'
        swtype = 'n/a'
        order = 0
    	divider = False
    	nowarn = False
    	badge = False

        if sensorid not in switchData:
            switchData[sensorid] = {}

        if sensorid in switchAliases:
            alias = switchAliases[sensorid]['alias']
            swtype = switchAliases[sensorid]['type']
            order = switchAliases[sensorid]['order']
            if 'subtype' in switchAliases[sensorid]:
                switchData[sensorid]['subtype'] = switchAliases[sensorid]['subtype']
            if 'nexaid' in switchAliases[sensorid]:
                switchData[sensorid]['nexaid'] = switchAliases[sensorid]['nexaid']
            if 'fab' in switchAliases[sensorid]:
                switchData[sensorid]['fab'] = switchAliases[sensorid]['fab']
            if 'divider' in switchAliases[sensorid]:
                switchData[sensorid]['divider'] = switchAliases[sensorid]['divider']
            if 'nowarn' in switchAliases[sensorid]:
                switchData[sensorid]['nowarn'] = switchAliases[sensorid]['nowarn']
            if 'badge' in switchAliases[sensorid]:
                switchData[sensorid]['badge'] = switchAliases[sensorid]['badge']

        switchData[sensorid]['id'] = sensorid
        switchData[sensorid]['alias'] = alias
        switchData[sensorid]['order'] = order
        switchData[sensorid]['type'] = swtype
        switchData[sensorid]['timestamp'] = timestamp
        switchData[sensorid]['state'] = state
        switchData[sensorid]['signal'] = signal

#
# Read last data
#

with open(args.last_file, 'rb') as csvfile:

    sqlData = csv.DictReader(csvfile, dialect="excel-tab")

    for row in sqlData:

        sensorid = row['sensorid']
        temperature = row['temperature']
        humidity = row['humidity']
        sensortype = row['packettype']
        datetime = row['datetime']
        signal = int(row['signal'])
        tnumedian = row['tnumedian']
        alias = 'n/a'
        location = 'n/a'
        order = 0

        if sensorid not in sensorData:
            sensorData[sensorid] = {}

        if sensorid in sensorAliases:
            alias = sensorAliases[sensorid]['alias']
            location = sensorAliases[sensorid]['location']
            order = sensorAliases[sensorid]['order']


        # Check if datetime is stale

        delta = relativedelta(now, parse(datetime))
        if delta.days > 0 or delta.hours > 0 or delta.minutes > 30:
            alias = alias + " ?"

        sensorData[sensorid]['order'] = order
        sensorData[sensorid]['signal'] = signal
        sensorData[sensorid]['alias'] = alias
        sensorData[sensorid]['id'] = sensorid
        sensorData[sensorid]['type'] = int(sensortype)
        sensorData[sensorid]['location'] = location
        sensorData[sensorid]['tnu'] = False
        sensorData[sensorid]['tnuselect'] = False
      
        sensorData[sensorid]['temperature'] = {'min': {}, 'max': {}, 'last': {}}
        sensorData[sensorid]['temperature']['last']['value'] = float(temperature)
        sensorData[sensorid]['temperature']['last']['timestamp'] = datetime

        sensorData[sensorid]['temperature']['min']['value'] = float(temperature)
        sensorData[sensorid]['temperature']['min']['timestamp'] = datetime

        sensorData[sensorid]['temperature']['max']['value'] = float(temperature)
        sensorData[sensorid]['temperature']['max']['timestamp'] = datetime

        if sensorid in tnu_sensors:
            sensorData[sensorid]['tnu'] = True



        if tnumedian:
            for s in tnumedian.split(','):
                if s not in sensorData:
                    sensorData[s] = {}
                sensorData[s]['tnuselect'] = True

        if int(sensortype) == 52:
            sensorData[sensorid]['humidity'] = {'min': {}, 'max': {}, 'last': {}}
            sensorData[sensorid]['humidity']['last']['value'] = float(humidity)
            sensorData[sensorid]['humidity']['last']['timestamp'] = datetime

            sensorData[sensorid]['humidity']['min']['value'] = float(humidity)
            sensorData[sensorid]['humidity']['min']['timestamp'] = datetime

            sensorData[sensorid]['humidity']['max']['value'] = float(humidity)
            sensorData[sensorid]['humidity']['max']['timestamp'] = datetime


#
# Read devices file
#

macs_mapping = dict(map(lambda x: x.split("="), args.macs.split(",")))

with open(args.devices_file, 'rb') as csvfile:

    sqlData = csv.DictReader(csvfile, dialect="excel-tab")

    for row in sqlData:
        mac = row['mac']
        if mac in macs_mapping:
            id = macs_mapping[mac]
            ip = row['ip']
            age = row['age']
            alias = deviceAliases[id]['alias']
            order = deviceAliases[id]['order']

	    if 'dividerabove' in deviceAliases[id]:
                dividerabove = deviceAliases[id]['dividerabove']
            else:
                dividerabove = False

	    if 'hilite' in deviceAliases[id]:
                hilite = deviceAliases[id]['hilite']
            else:
                hilite = False

            datetime = row['datetime']
            delta = format_timedelta(int(row['age']), threshold=1, granularity='second',format='medium', locale='sv_SE')

            if int(age) <= args.device_max_age:
	    	sw = {'alias': alias, 'id': id, 'timestamp': datetime, 'order': order, 'ip': ip, 'age': age,'delta': delta, 'hilite': hilite}
		if dividerabove is True:
		    sw['dividerabove'] = True
		result['devices'].append(sw)


#
# Read min temps
#

readFile(args.min_file, 'temperature', 'mintemp', 'min')


#
# Read max temps
#

readFile(args.max_file, 'temperature', 'maxtemp', 'max')


#
# Read min humidity
#

readFile(args.hum_min_file, 'humidity', 'minhumidity', 'min')


#
# Read max humidity
#

readFile(args.hum_max_file, 'humidity', 'maxhumidity', 'max')


readSystemFile(args.system_file)

if args.cities_file:
    readCitiesFile(args.cities_file)

if args.tnu_history_file:
    readTrendFile(args.tnu_history_file)

#
# How many hours with missing signals
#

if args.missing_file:
    missingcount = readMissingFile(args.missing_file)
    result['hoursmissingcount'] = missingcount

#
# Collect all data and output json...
#

for sensorid in switchData:
    result['switches'].append(switchData[sensorid])


for sensorid in sensorData:
    result['sensors'].append(sensorData[sensorid])


result['switches'] = sorted(result['switches'], key=lambda k: k['order'])
result['sensors'] = sorted(result['sensors'], key=lambda k: (k['temperature']['last']['value'], -k['order']), reverse=True)
result['devices'] = sorted(result['devices'], key=lambda k: k['order'])
result['lasthour'] = sorted(result['lasthour'], key=lambda k: (k['count'], -k['order']), reverse=True)

# Sort system entries

for x in result['system']:
    result['system'][x] = sorted(result['system'][x], key=lambda k: k['order'])

# Create toplist

toplist(result)
result['toplist']['coldest'] = sorted(result['toplist']['coldest'], key=lambda k: (k['value'], k['alias']))
result['toplist']['warmest'] = sorted(result['toplist']['warmest'], key=lambda k: (-k['value'], k['alias']))


# print json.dumps(sensorData, indent=2, sort_keys=True)
print json.dumps(result, indent=2, sort_keys=True, encoding="utf-8")

#!/usr/bin/env python3

import argparse
import json
import syslog
import sys


def processSensors(a, swid, value, humidity, stamp, signal):
    for i, _ in enumerate(a):
        sensorid = a[i]['id']
        if sensorid == swid:
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

            break


def processSwitches(a, swid, state, stamp, signal):
    for i, _ in enumerate(a):
        this_id = a[i]['id']
        if this_id == swid:
            a[i]['timestamp'] = stamp
            a[i]['state'] = state
            a[i]['signal'] = signal
            break


#
# main starts here
#

def main():

    syslog.openlog(facility=syslog.LOG_DAEMON)

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

    args = parser.parse_args()

    with open(args.file) as data_file:
        try:
            json_data = json.load(data_file)

            if args.sensor_id != '':
                if 'sensors' in json_data:
                    processSensors(json_data['sensors'], args.sensor_id, args.sensor_value, args.sensor_humidity, args.stamp, args.signal)
                    print(json.dumps(json_data, indent=2, sort_keys=True))

            if args.switch_id != '':
                if 'switches' in json_data:
                    processSwitches(json_data['switches'], args.switch_id, args.switch_state, args.stamp, args.signal)
                    print(json.dumps(json_data, indent=2, sort_keys=True))
            sys.exit(0)

        except Exception:
            sys.exit(1)


if __name__ == '__main__':
    main()

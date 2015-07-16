#!/usr/bin/env python
# coding=iso-8859-1

import re
import argparse
import curses
import curses.wrapper
import threading
import locale
import sys
import Queue

from os import path
from pubnub import Pubnub

sys.path.append(path.dirname(path.abspath(__file__)) + '/lib')


from FileFollower import FileFollower
from Sensors import SensorList



#
# Parse arguments
#

parser = argparse.ArgumentParser(description='Simple top for sensors')

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


args = parser.parse_args()


#
#	Variables
#

locale.setlocale(locale.LC_ALL, "")

re_50 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;50;..;..;(....);\d;(\d);(.*)')
re_52 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;52;..;..;(....);\w+;(.*?);(\d+);\d;(\d)')
re_tnu = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+\d+\s+\d+\s+(.*)')
re_rest = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+PI_core_temp\s+\-\>\s+(\d{2,3}\.\d{2,3})')

trendsize = 14
windowWidth = 56


lock = threading.Lock()
lineQueue = Queue.Queue()
sensors = SensorList(trendsize=trendsize)

frameColor = 32
headerColor = 40

aliasColor = 0
stampColor = 245
darkColor = 240

sensorHeaders = [
    ("artificial", "Temperatur.nu"),
    ("outside", "Utomhus"),
    ("outside_average", "Medel Utomhus"),
    ("inside", "Inomhus"),
    ("humidity", "Luftfuktighet"),
    ("pi", "Pi")
]


pubnub = Pubnub(publish_key=args.pubnub_pubkey,
                    subscribe_key=args.pubnub_subkey,
                    secret_key='',
                    cipher_key='',
                    ssl_on=False
)


# debugFile = open('/tmp/ttop.log', 'w' ,0)


def print_HeaderAt(s, o, w, t):
    hbar = u'\u2500'

    if o == 0:
        lch = u'\u250c'
        rch = u'\u2510'
    else:
        lch = u'\u251c'
        rch = u'\u2524'

    tlen = len(t)
    lbarlen = (w - 4 - tlen) / 2
    rbarlen = lbarlen + len(t) % 2

    lstr = (lch + hbar * lbarlen + ' ').encode('utf-8', 'ignore')
    rstr = (' ' + hbar * rbarlen + rch).encode('utf-8', 'ignore')

    s.addstr(o, 0, lstr, curses.color_pair(frameColor))
    s.addstr(o, 2 + lbarlen, t, curses.color_pair(headerColor))
    s.addstr(o, w - 2 - rbarlen, rstr, curses.color_pair(frameColor))


def print_vbarsAt(s, o, w):
    s.insstr(o, 0, (u'\u2502').encode('utf-8', 'ignore'), curses.color_pair(frameColor))
    s.insstr(o, w - 1, (u'\u2502').encode('utf-8', 'ignore'), curses.color_pair(frameColor))


def print_bottomHeaderAt(s, o, w):
    hstr = (u'\u2514' + u'\u2500' * (w - 2) + u'\u2518').encode('utf-8', 'ignore')
    s.insstr(o, 0, hstr, curses.color_pair(frameColor))

#
# process_log_line
#


def process_log_line(filename, line, stdscr):
    id = ''
    row = 0
    lastRowUpdated = 1
    stamp = '00:00:00'
    signal = ' '
    
    m = re_50.match(line)
    if m:
        stamp = m.group(1)
        id = m.group(2)
        signal = m.group(3)
        temp = m.group(4)

    m = re_52.match(line)
    if m:
        stamp = m.group(1)
        id = m.group(2)
        temp = m.group(3)
        humidity = m.group(4)
        signal = m.group(5)

	if id == '8700':
            sensors.settemp(id='FFF1', stamp=stamp, temp=float(humidity),signal=signal)
        if id == '9700':
            sensors.settemp(id='FFF0', stamp=stamp, temp=float(humidity),signal=signal)
        if id == 'A700':
            sensors.settemp(id='FFF2', stamp=stamp, temp=float(humidity),signal=signal)

    m = re_tnu.match(line)
    if m:
        stamp = m.group(1)
        id = '0000'
        temp = m.group(2)

    m = re_rest.match(line)
    if m:
        stamp = m.group(1)
        id = 'FFFA'
        temp = m.group(2)

    if id != '':
        sensors.settemp(id=id, stamp=stamp, temp=temp,signal=signal)
        # debugFile.write(id + " -> " + stamp + " -> " + sensors.sensorFormatTemp(temp) + "\n")

    stdscr.erase()

    for loc, head in sensorHeaders:

        print_HeaderAt(stdscr, row, windowWidth, head)
        row = row + 1
        startrow = row

        for rid in sensors.getsidsfromlocation(loc):
            alias = sensors.getsensoralias(rid)
	    histtemp = sensors.getsensorhistformatted(rid)
            temp = sensors.getsensortempformatted(rid)
            stamp = sensors.getsensorstamp(rid)
            signal = sensors.getsensorsignal(rid)
            trend = sensors.getsensorsparkline(rid)
            offset = startrow + sensors.getsensoroffset(rid)
            if id == rid:
                lastRowUpdated = offset

            print_vbarsAt(stdscr, offset, windowWidth)

	    alias_colstart = 2
	    signal_colstart = 14
	    stamp_colstart = 16
	    hist_colstart = 28
	    trend_colstart = hist_colstart + 6
	    temp_colstart = trend_colstart + trendsize + 1

            stdscr.addstr(offset, alias_colstart, alias, curses.color_pair(aliasColor))
            stdscr.addstr(offset, signal_colstart, signal, curses.color_pair(darkColor))
            stdscr.addstr(offset, stamp_colstart, stamp, curses.color_pair(stampColor))
	    
            stdscr.addstr(offset, hist_colstart, histtemp,curses.color_pair(darkColor))
	    stdscr.addstr(offset, trend_colstart, trend)
            stdscr.addstr(offset, temp_colstart, temp)
	    
            row = row + 1

    offset = offset + 1
    print_bottomHeaderAt(stdscr, offset, windowWidth)

    stdscr.move(lastRowUpdated, 2)
    stdscr.refresh()

#
# pn_send_status
#

def pn_send_status(status):
    
    msg = {}
    msg['type'] = 'status'
    msg['status'] = {'ttop': status}
    
    pubnub.publish(args.pubnub_channel, str(msg))
 


#
# Main program
#


def ttop(stdscr):
    stdscr.nodelay(True)


    pn_send_status('started')


    # Color stuff
    curses.start_color()
    curses.use_default_colors()
    for i in range(0, curses.COLORS):
        curses.init_pair(i + 1, i, -1+1)

    # Temperatur.nu
    sensors.addsensor(id='0000', alias='Rapporterat', location='artificial')

    # Outdoor
    sensors.addsensor(id='3B00', alias='Anna:s', offset=0)
    sensors.addsensor(id='0700', alias='Förrådet', offset=1)
    sensors.addsensor(id='7500', alias='Hammocken', offset=2)
    sensors.addsensor(id='8700', alias='Tujan', offset=3)
    sensors.addsensor(id='A700', alias='Komposten', offset=4)
    sensors.addsensor(id='AC00', alias='Cyklarna', offset=5)

    # Indoor
    sensors.addsensor(id='9700', alias='Bokhyllan', location='inside')

    # Pi
    sensors.addsensor(id='FFFA', alias='Pi', location='pi')

    # Average for outdoor
    sensors.addaverage(id='FFFF', alias='Medel')

    # Humidity
    sensors.addsensor(id='FFF0', alias='Bokhyllan', location='humidity', offset=0)
    sensors.addsensor(id='FFF1', alias='Tujan',     location='humidity', offset=1)
    sensors.addsensor(id='FFF2', alias='Komposten', location='humidity', offset=2)

    process_log_line("", "", stdscr)

    # Create new threads

    thread1 = FileFollower('/var/rfxcmd/sensor.csv', lineQueue,1)
    thread2 = FileFollower('/var/rfxcmd/temperatur-nu.log', lineQueue, 15)
    thread3 = FileFollower('/var/rfxcmd/update-rest.log', lineQueue, 15)

    thread1.setDaemon(True)
    thread2.setDaemon(True)
    thread3.setDaemon(True)

    # Start new Threads
    thread1.start()
    thread2.start()
    thread3.start()

    #
    # Waith for input
    #

    while True:
        try:
            line = lineQueue.get()
            process_log_line("", line, stdscr)
        except:
            raise

        try:
            key = stdscr.getkey()
        except:  # in no delay mode getkey raise and exeption if no key is press
            key = None

        if key == "r":  # of we got a space then break
            sensors.resettrend()
            process_log_line("", "", stdscr)

        if key == "q":  # of we got a space then break
            break

    thread1.stop()
    thread2.stop()
    thread3.stop()

    pn_send_status('stopped')



# Run through wrapper...

curses.wrapper(ttop)
print "Bye bye..."
exit(0)

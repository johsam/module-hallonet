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
import socket
import time

from math import sin, radians


from os import path
from pubnub import Pubnub

sys.path.append(path.dirname(path.abspath(__file__)) + '/lib')


from FileFollower import FileFollower
from Sensors import SensorList
from drawille import drawille
from graph import *

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

parser.add_argument(
    '--seed', required=False,
    default='',
    dest='seedfile',
    help='Initial history data'
)

parser.add_argument(
    '--max-vals', required=False,
    type=int,
    default=145,
    dest='maxvals',
    help='Length of data to keep'
)


args = parser.parse_args()


#
#   Variables
#

locale.setlocale(locale.LC_ALL, "")

re_50 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});(\d+);50;..;..;(....);\d;(\d);(.*)')
re_52 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;52;..;..;(....);\w+;(.*?);(\d+);\d;(\d)')
re_tnu = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+\d+\s+\d+\s+(.*?)\s+')
re_rest = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+PI_core_temp\s+\-\>\s+(\d{2,3}\.\d{2,3})')

trendsize = 14
windowWidth = 58


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
    ("outside_median", "Median Utomhus"),
    ("inside", "Inomhus"),
    ("humidity", "Luftfuktighet"),
    ("graph", "Historik")
]


pubnub = Pubnub(publish_key=args.pubnub_pubkey,
                subscribe_key=args.pubnub_subkey,
                secret_key='',
                cipher_key='',
                ssl_on=False
                )


history = graph.Graph(windowWidth - 2, 7, args.maxvals)

if args.seedfile != '':
    with open(args.seedfile) as seedfile:
        for line in seedfile:
            s = str.split(line, "\t")
            history.append(int(s[0]), float(s[1]))

#debugFile = open('/tmp/ttop.log', 'w' ,0)


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
    temp = None

    m = re_50.match(line)
    if m:
        stamp = m.group(1)
        epoch = m.group(2)
        id = m.group(3)
        signal = m.group(4)
        temp = m.group(5)

        #if id == 'CF00':
    #    history.append(int(epoch),float(temp))
    #    history.draw()

    m = re_52.match(line)
    if m:
        stamp = m.group(1)
        id = m.group(2)
        temp = m.group(3)
        humidity = m.group(4)
        signal = m.group(5)

        if id == 'A700':
            sensors.settemp(id='FFF0', stamp=stamp, temp=float(humidity),signal=signal)
        if id == '8700':
            sensors.settemp(id='FFF1', stamp=stamp, temp=float(humidity),signal=signal)
        if id == 'B700':
            sensors.settemp(id='FFF2', stamp=stamp, temp=float(humidity),signal=signal)
        if id == '8900':
            sensors.settemp(id='FFF3', stamp=stamp, temp=float(humidity),signal=signal)
        if id == '9700':
            sensors.settemp(id='FFF4', stamp=stamp, temp=float(humidity), signal=signal)

    m = re_tnu.match(line)
    if m:
        stamp = m.group(1)
        id = '0000'
        temp = m.group(2)
    	history.append(int(time.time()), float(temp))
    	history.draw()

    m = re_rest.match(line)
    if m:
        stamp = m.group(1)
        id = 'FFFA'
        temp = m.group(2)

    if id != '':
        sensors.settemp(id=id, stamp=stamp, temp=temp, signal=signal)

    stdscr.erase()

    doLines = history.getLines()
    doAverage = history.getAverage()
    doBresenHam = history.getBresenHam()

    title = "Historik"
    options = ""

    if doAverage is False:
        options = options + "a"

    if doLines is False:
        options = options + "l"

    if doBresenHam is False:
        options = options + "b"

    if len(options) > 0:
        title = title + " (-" + options + ")"

    sensorHeaders[6] = (sensorHeaders[6][0], title)

    for loc, head in sensorHeaders:

        print_HeaderAt(stdscr, row, windowWidth, head)
        row = row + 1
        startrow = row

    	sids = sensors.getsidsfromlocation(loc)
	
	# Sort temp:s descending if location = 'outside'
	
	if loc == 'outside':
	    sids = sorted(sids, key=lambda k: (sensors.getsensortemp(k),sensors.getsensorsignal(k)),reverse = True) 
	    # Reorder offset
	    for idx, rid in enumerate(sids):
	    	sensors.setOffset(rid,idx)

	for rid in sids:
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
            signal_colstart = 18
            stamp_colstart = signal_colstart + 2
            hist_colstart = stamp_colstart + 10
            trend_colstart = hist_colstart + 6
            temp_colstart = trend_colstart + trendsize + 1

            stdscr.addstr(offset, alias_colstart, alias, curses.color_pair(aliasColor))
            stdscr.addstr(offset, signal_colstart, signal, curses.color_pair(darkColor))
            stdscr.addstr(offset, stamp_colstart, stamp, curses.color_pair(stampColor))

            stdscr.addstr(offset, hist_colstart, histtemp, curses.color_pair(darkColor))
            stdscr.addstr(offset, trend_colstart, trend)
            stdscr.addstr(offset, temp_colstart, temp)

            row = row + 1

    offset = offset + 2
    #c = [160, 166, 172, 32, 26, 20]
    #c = [88, 89, 90, 91, 92, 93]
    i = 0
    for r in history.rows():
        print_vbarsAt(stdscr, offset, windowWidth)
        stdscr.addstr(offset, 1, "".join(r).encode('utf-8'))
        offset = offset + 1
        i = i + 1

    print_bottomHeaderAt(stdscr, offset, windowWidth)

    stdscr.move(lastRowUpdated, 2)
    stdscr.refresh()


#
# pn_send_state
#

def pn_send_state(state):
    ip = [(s.connect(('8.8.8.8', 80)), s.getsockname()[0], s.close()) for s in [socket.socket(socket.AF_INET, socket.SOCK_DGRAM)]][0][1]
    now = time.strftime("%F %T")

    msg = {}
    msg['type'] = 'status'
    msg['info'] = {'application': 'ttop', 'ip': ip, 'version': '1.0', 'timestamp': now}
    msg['status'] = {'state': state}

    pubnub.publish(args.pubnub_channel, msg)


#
# Main program
#


def ttop(stdscr):
    stdscr.nodelay(True)

    pn_send_state('started')

    # Color stuff
    curses.start_color()
    curses.use_default_colors()
    for i in range(0, curses.COLORS):
        curses.init_pair(i + 1, i, -1+1)

    # Temperatur.nu
    sensors.addsensor(id='0000', alias='Rapporterat', location='artificial')

    # Outdoor
    #sensors.addsensor(id='3B00', alias='Anna:s', offset=0)
    sensors.addsensor(id='0700', alias='Förrådet Tak', offset=0)
    sensors.addsensor(id='B700', alias='Stuprännan', offset=1)
    sensors.addsensor(id='8900', alias='Stuprännan (v)', offset=2)
    sensors.addsensor(id='CF00', alias='Hammocken', offset=3)
    sensors.addsensor(id='8700', alias='Tujan', offset=4)
    sensors.addsensor(id='A700', alias='Komposten', offset=5)
    sensors.addsensor(id='AC00', alias='Cyklarna', offset=6)

    # Indoor
    sensors.addsensor(id='9700', alias='Bokhyllan', location='inside', offset=0)
    sensors.addsensor(id='8F00', alias='Golv TV:n', location='inside', offset=1)

    # Pi
    #sensors.addsensor(id='FFFA', alias='Pi', location='pi')

    # Average for outdoor
    sensors.addaverage(id='FFFF', alias='Medel')

    # median for outdoor
    sensors.addmedian(id='EEEE', alias='Median')

    # Humidity
    sensors.addsensor(id='FFF0', alias='Komposten', location='humidity', offset=0)
    sensors.addsensor(id='FFF1', alias='Tujan', location='humidity', offset=1)
    sensors.addsensor(id='FFF2', alias='Stuprännan',location='humidity', offset=2)
    sensors.addsensor(id='FFF3', alias='Stuprännan (v)', location='humidity', offset=3)
    sensors.addsensor(id='FFF4', alias='Bokhyllan', location='humidity', offset=4)

    history.draw()

    process_log_line("", "", stdscr)

    # Create new threads

    thread1 = FileFollower('/var/rfxcmd/sensor.csv', lineQueue, 1)
    thread2 = FileFollower('/var/rfxcmd/temperatur-nu.log', lineQueue, 15)

    thread1.setDaemon(True)
    thread2.setDaemon(True)

    # Start new Threads
    thread1.start()
    thread2.start()

    #
    # Waith for input
    #

    while True:
        try:
            log_line = lineQueue.get(True, 2)
            process_log_line("", log_line, stdscr)
        except Queue.Empty:
            pass
        except:
            raise

        try:
            key = stdscr.getkey()
        except:
            key = None

        if key == "r":
            sensors.resettrend()
            process_log_line("", "", stdscr)

        if key == "a":
            history.toggleAverage()
            history.draw()
            process_log_line("", "", stdscr)

        if key == "l":
            history.toggleLines()
            history.draw()
            process_log_line("", "", stdscr)

        if key == "b":
            history.toggleBresenham()
            history.draw()
            process_log_line("", "", stdscr)

        if key == "q":
                break

    thread1.stop()
    thread2.stop()

    pn_send_state('stopped')


# Run through wrapper...

curses.wrapper(ttop)
print "Bye bye..."
exit(0)

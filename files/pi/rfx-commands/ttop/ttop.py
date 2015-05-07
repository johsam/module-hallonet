#!/usr/bin/env python
# coding=iso-8859-1

import re
import curses
import curses.wrapper
import threading
import locale
import sys
import json
import Queue

from os import path

sys.path.append(path.dirname(path.abspath(__file__)) + '/lib')

import sparkline

from FileFollower import FileFollower
from Sensors import SensorList

locale.setlocale(locale.LC_ALL, "")

re_50 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;50;..;..;(....);\d;\d;(.*)')
re_52 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;52;..;..;(....);\w+;(.*?);(\d+;)\d+;\d+')
re_tnu = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+\d+\s+\d+\s+(.*)')

aliasWidth = 14
lock = threading.Lock()
lineQueue = Queue.Queue()
sensors = SensorList(trendsize=10)


sensorHeaders = [
    ("artificial", "================= Temperatur.nu ================="),
    ("outside", "==================== Utomhus ===================="),
    ("outside_average", "==================== Medel(U) ==================="),
    ("inside", "==================== Inomhus ====================")
]


def process_log_line(filename, line, stdscr):
    id = ''
    row = 0
    last = 0
    stamp = '00:00:00'
    #print json.dumps(sensors.sensors, sort_keys=True, indent=4)

    m = re_50.match(line)
    if m:
        stamp = m.group(1)
        id = m.group(2)
        temp = m.group(3)

    m = re_52.match(line)
    if m:
        stamp = m.group(1)
        id = m.group(2)
        temp = m.group(3)

    m = re_tnu.match(line)
    if m:
        stamp = m.group(1)
        id = '0000'
        temp = m.group(2)

    if id != '':
        sensors.settemp(id=id, stamp=stamp, temp=temp)

    stdscr.erase()

    for loc, head in sensorHeaders:
        #stdscr.addstr(row, 0, head, curses.A_STANDOUT)
        stdscr.addstr(row, 0, head)
        row = row + 1
        startrow = row

        for rid in sensors.getsidsfromlocation(loc):
            alias = sensors.getsensoralias(rid)
            temp = sensors.getsensortempformatted(rid)
            stamp = sensors.getsensorstamp(rid)
            trend = sensors.getsensorsparkline(rid)
            offset = startrow + sensors.getsensoroffset(rid)
            if id == rid:
                last = offset
            stdscr.addstr(offset, 0, alias)
            stdscr.addstr(offset, aliasWidth, stamp)
            stdscr.addstr(offset, aliasWidth * 2, trend)
            stdscr.addstr(offset, aliasWidth * 3, temp)

            row = row + 1

    stdscr.move(last, 0)
    stdscr.refresh()

#
# Main program
#


def ttop(stdscr):
    stdscr.nodelay(True)

    # Temperatur.nu
    sensors.addsensor(id='0000', alias='Rapporterat', location='artificial')

    # Outdoor
    sensors.addsensor(id='E400', alias='Anna:s', offset=0)
    sensors.addsensor(id='0700', alias='Förrådet', offset=1)
    sensors.addsensor(id='7500', alias='Hammocken', offset=2)
    sensors.addsensor(id='8700', alias='Tujan', offset=3)
    sensors.addsensor(id='AC00', alias='Cyklarna', offset=4)
    sensors.addaverage(id='FFFF', alias='Medel')

    # Indoor
    sensors.addsensor(id='9700', alias='Bokhyllan', location='inside')

    # Average for outdoor
    sensors.addaverage(id='FFFF', alias='Medel')

    process_log_line("", "", stdscr)

    # Create new threads
    thread1 = FileFollower('/var/rfxcmd/sensor.csv', lineQueue)
    thread2 = FileFollower('/var/rfxcmd/temperatur-nu.log', lineQueue, 30)

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
            line = lineQueue.get()
            process_log_line("", line, stdscr)
        except:
            raise

        try:
            key = stdscr.getkey()
        except:  # in no delay mode getkey raise and exeption if no key is press
            key = None
        if key == "q":  # of we got a space then break
            break

    # os.system("""bash -c 'read -s -n 1'""")

    thread1.stop()
    thread2.stop()

# Run through wrapper...

curses.wrapper(ttop)
print "Bye bye..."
exit(0)

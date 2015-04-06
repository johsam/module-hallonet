#!/usr/bin/env python
# coding=iso-8859-1

import re
import curses
import curses.wrapper
import threading
import locale
import Queue

from FileFollower import FileFollower

locale.setlocale(locale.LC_ALL, "")

re_50 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;50;..;..;(....);\d;\d;(.*)')
re_52 = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2});\d+;52;..;..;(....);\w+;(.*?);(\d+;)\d+;\d+')
re_tnu = re.compile('\d{4}-\d{2}-\d{2}\s(\d{2}:\d{2}:\d{2})\s+\d+\s+\d+\s+(.*)')

aliasWidth = 14
lock = threading.Lock()
lineQueue = Queue.Queue()


sensorHeaders = [
    ("artificial", "========== Temperatur.nu =========="),
    ("outside", "============= Utomhus ============="),
    ("inside", "============= Inomhus =============")
]

sensorAliases = {
    "0000": {
        "alias": "Rapporterat",
        "location": "artificial",
        "offset": 0,
        "stamp": "00:00:00",
        "temp": 0.0
    },

    "E400": {
        "alias": "Anna:s",
        "location": "outside",
        "offset": 0,
        "stamp": "00:00:00",
        "temp": 0.0
    },

    "0700": {
        "alias": "Förrådet",
        "location": "outside",
        "offset": 1,
        "stamp": "00:00:00",
        "temp": 0.0
    },


    "7500": {
        "alias": "Hammocken",
        "location": "outside",
        "offset": 2,
        "stamp": "00:00:00",
        "temp": 0.0
    },

    "8700": {
        "alias": "Tujan   ",
        "location": "outside",
        "offset": 3,
        "stamp": "00:00:00",
        "temp": 0.0
    },

    "AC00": {
        "alias": "Cyklarna",
        "location": "outside",
        "offset": 4,
        "stamp": "00:00:00",
        "temp": 0.0
    },

    "FFFF": {
        "alias": "Medel",
        "location": "outside",
        "offset": 5,
        "stamp": "00:00:00",
        "temp": 0.0
    },


    "9700": {
        "alias": "Bokhyllan",
        "location": "inside",
        "offset": 0,
        "stamp": "00:00:00",
        "temp": 0.0
    }

}


def process_log_line(filename, line, stdscr):
    id = ''
    row = 0
    last = 0
    stamp = '00:00:00'

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
        if id in sensorAliases:
            sensorAliases[id]['stamp'] = stamp
            sensorAliases[id]['temp'] = "{:.2f}".format(float(temp))

    # Update average
    sum = 0.0
    cnt = 0
    for s in sensorAliases:
        if s != 'FFFF' and sensorAliases[s]['location'] == 'outside' and sensorAliases[s]['stamp'] != '00:00:00':
            sum = sum + float(sensorAliases[s]['temp'])
            cnt = cnt + 1

    if cnt != 0:
        sensorAliases['FFFF']['stamp'] = stamp
        sensorAliases['FFFF']['temp'] = "{:.2f}".format(float(sum / cnt))

    stdscr.erase()

    for l, h in sensorHeaders:
        stdscr.addstr(row, 0, h, curses.A_STANDOUT)
        row = row + 1
        startrow = row

        for s in sensorAliases:
            location = str(sensorAliases[s]['location'])
            if location == l:
                alias = sensorAliases[s]['alias']
                stamp = sensorAliases[s]['stamp']
                temp = str(sensorAliases[s]['temp']).rjust(7, ' ')

                offset = startrow + sensorAliases[s]['offset']

                if s == id:
                    last = offset

                stdscr.addstr(offset, 0, alias)
                stdscr.addstr(offset, aliasWidth, stamp)
                stdscr.addstr(offset, aliasWidth * 2, temp)

                row = row + 1
        # row = row + 1

    stdscr.move(last, 0)
    stdscr.refresh()

#
# Main program
#


def ttop(stdscr):
    stdscr.nodelay(True)

    process_log_line("", "", stdscr)

    # Create new threads
    thread1 = FileFollower('/var/rfxcmd/sensor.csv', lineQueue)
    thread2 = FileFollower('/var/rfxcmd/temperatur-nu.log', lineQueue,30)

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
            break

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

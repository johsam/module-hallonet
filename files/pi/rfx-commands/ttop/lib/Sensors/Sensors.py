# coding=iso-8859-1
# import json
import sys
from os import path

sys.path.append(path.dirname(path.abspath(__file__)) + '/../')
import sparkline


def iterable(cls):
    def iterfn(self):
        iters = dict((x, y) for x, y in cls.__dict__.items() if x[:2] != '__')
        iters.update(self.__dict__)

        for x, y in iters.items():
            yield x, y

    cls.__iter__ = iterfn
    return cls


@iterable
class Sensor(object):
    alias = ''
    location = ''
    offset = 0
    stamp = '00:00:00'
    trend = []
    temp = 0.0
    trendsize = 0

    def __init__(self, alias='', location='', offset=0, trendsize=5):
        self.alias = alias
        self.location = location
        self.offset = offset
        self.trendsize = trendsize
        self.trend = [0.0] * trendsize
        self.trendempty = True


class SensorList(object):
    sensors = {}
    trendsize = 5

    def __init__(self, trendsize=5):
        self.trendsize = trendsize

    def __getsensor(self, id):
        if id in self.sensors:
            return self.sensors[id]
        else:
            return {}

    def addsensor(self, id, alias, location='outside', offset=0, trendsize=trendsize):
        self.sensors[id] = dict(Sensor(alias=alias, location=location, offset=offset, trendsize=self.trendsize))

    def addaverage(self, id, alias, location='outside', trendsize=trendsize):
        self.sensors[id] = dict(Sensor(alias=alias, location=location + '_average', trendsize=self.trendsize))

    def calcaverage(self, location):
        sum = 0.0
        count = 0
        avgtmp = 0.0

        # All sensors matching location

        for c in self.getsidsfromlocation(location):
            s = self.__getsensor(c)
            sum = sum + s['temp']
            count = count + 1
            # print location, c, s['temp']

        if count != 0:
            avgtmp = sum / count

        # print count, sum, avgtmp

        return avgtmp

    def settemp(self, id, temp, stamp='00:00:00'):
        if id in self.sensors:
            # Make sure temp is a float
            temp = float(temp)

            self.sensors[id]['temp'] = temp
            self.sensors[id]['stamp'] = stamp

            if self.sensors[id]['trendempty'] is True:
                self.sensors[id]['trendempty'] = False
                for i in range(0, self.trendsize):
                    self.sensors[id]['trend'][i] = temp
            else:
                self.sensors[id]['trend'].pop(0)
                self.sensors[id]['trend'].append(temp)

            offset = self.sensors[id]['offset']

            # Calculate average

            avgtmp = self.calcaverage(self.sensors[id]['location'])

            # Update average for all average sensors

            for avgid in self.getsidsfromlocation(self.sensors[id]['location'] + '_average'):
                oldtemp = self.getsensortemp(avgid)
                if oldtemp != avgtmp:
                    self.settemp(id=avgid, temp=avgtmp, stamp=stamp)

    def getsidsfromlocation(self, location):
        result = []
        for s in self.sensors:
            if self.sensors[s]['location'] == location:
                result.append(s)
        return result

    def getsensoralias(self, id):
        s = self.__getsensor(id)
        if 'alias' in s:
            return s['alias']
        return ''

    def getsensortemp(self, id):
        s = self.__getsensor(id)
        if 'temp' in s:
            return s['temp']
        return 0.0

    def getsensortempformatted(self, id):
        s = self.__getsensor(id)
        result = 0.0
        if 'temp' in s:
            result = s['temp']
        return "{:.1f}".format(float(result)).rjust(7, ' ')

    def getsensorstamp(self, id):
        s = self.__getsensor(id)
        if 'stamp' in s:
            return s['stamp']
        return '00:00:00'

    def getsensorsparkline(self, id):
        s = self.__getsensor(id)
        if 'trend' in s:
            return sparkline.sparkify(s['trend']).encode('utf-8')
        return sparkline.sparkify([]).encode('utf-8')

    def getsensoroffset(self, id):
        s = self.__getsensor(id)
        if 'stamp' in s:
            return s['offset']
        return 0


def main():

    sensors = SensorList(trendsize=10)

    sensors.addsensor(id='0000', alias='Rapporterat', location='artificial')

    sensors.addsensor(id='E400', alias='Anna:s', offset=0)
    sensors.addsensor(id='0700', alias='Förrådet', offset=1)
    sensors.addsensor(id='B500', alias='Hammocken', offset=2)
    sensors.addsensor(id='8700', alias='Tujan', offset=3)
    sensors.addsensor(id='AC00', alias='Cyklarns', offset=4)
    sensors.addaverage(id='FFFF', alias='Medel')

    sensors.addsensor(id='9700', alias='Bokhyllan', location='inside')

    # Set some temps

    sensors.settemp(id='E400', stamp='10:00:00', temp=2.5)
    sensors.settemp(id='E400', stamp='10:00:05', temp=2.1)
    # sensors.settemp(id='E400',stamp='10:00:10',temp=1.9)
    # sensors.settemp(id='E400',stamp='10:00:11',temp=2.3)
    # sensors.settemp(id='E400',stamp='10:00:12',temp=2.2)

    sensors.settemp(id='8700', stamp='10:00:20', temp=2)
    # sensors.settemp(id='9700',stamp='10:00:10',temp=23.1)

    # print json.dumps(sensors.sensors,sort_keys=True,indent=4)

    for l in ['artificial', 'outside', 'outside_average', 'inside']:
        print '=== ' + l + ' ==='
        for id in sensors.getsidsfromlocation(l):
            alias = sensors.getsensoralias(id)
            temp = sensors.getsensortemp(id)
            stamp = sensors.getsensorstamp(id)
            trend = sensors.getsensorsparkline(id)
            print alias, stamp, temp, trend


if __name__ == "__main__":
    main()

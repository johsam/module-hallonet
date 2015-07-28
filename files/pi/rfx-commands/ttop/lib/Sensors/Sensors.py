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
    signal = ' '
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

    def addmedian(self, id, alias, location='outside', trendsize=trendsize):
        self.sensors[id] = dict(Sensor(alias=alias, location=location + '_median', trendsize=self.trendsize))

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

    def median(self,numbers):
        return (sorted(numbers)[int(round((len(numbers) - 1) / 2.0))] + sorted(numbers)[int(round((len(numbers) - 1) // 2.0))]) / 2.0

    def calcmedian(self, location):
	median = 0.0
	values = []
	
        # All sensors matching location

        for c in self.getsidsfromlocation(location):
            s = self.__getsensor(c)
            values.append(s['temp'])
 
	median = self.median(values)
	
	#import json
	#debugFile = open('/tmp/ttop.log', 'a' ,0)
	#debugFile.write(json.dumps(location));
	#debugFile.write(json.dumps(sorted(values)));
	#debugFile.write(json.dumps(median));
	#debugFile.write("\n");

	return median

    def settemp(self, id, temp, stamp='00:00:00',signal=' '):
        global debugFile
	if id in self.sensors:

	    # Make sure temp is a float
            temp = float(temp)
            
	    oldtemp = self.sensorFormatTemp(self.sensors[id]['temp'])
	    newtemp = self.sensorFormatTemp(temp)

            self.sensors[id]['temp'] = temp
            self.sensors[id]['stamp'] = stamp
            self.sensors[id]['signal'] = signal

            if self.sensors[id]['trendempty'] is True:
                self.sensors[id]['trendempty'] = False
                for i in range(0, self.trendsize):
                    self.sensors[id]['trend'][i] = temp
            else:
                if newtemp != oldtemp:
		    self.sensors[id]['trend'].pop(0)
                    self.sensors[id]['trend'].append(temp)

            offset = self.sensors[id]['offset']

            
	    if self.sensors[id]['location'] != 'outside':
	        return
	    
	    # Calculate average

            avgtmp = self.calcaverage(self.sensors[id]['location'])
            d_avgtmp = self.sensorFormatTemp(avgtmp)

            # Update average for all average sensors

            for avgid in self.getsidsfromlocation(self.sensors[id]['location'] + '_average'):
		d_oldtemp = self.sensorFormatTemp(self.getsensortemp(avgid))
		
		if d_oldtemp != d_avgtmp:
                    self.settemp(id=avgid, temp=avgtmp, stamp=stamp)

           # Calculate median

            mediantmp = self.calcmedian(self.sensors[id]['location'])
            d_mediantmp = self.sensorFormatTemp(mediantmp)

            # Update average for all median sensors

            for medid in self.getsidsfromlocation(self.sensors[id]['location'] + '_median'):
		d_oldtemp = self.sensorFormatTemp(self.getsensortemp(medid))
		
		if d_oldtemp != d_mediantmp:
                    self.settemp(id=medid, temp=mediantmp, stamp=stamp)



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

    def sensorFormatTemp(self, temp):
        return "{:.1f}".format(round(float(temp),1))

    def getsensortempformatted(self, id):
        s = self.__getsensor(id)
        temp = 0.0
        if 'temp' in s:
            temp = s['temp']
	return self.sensorFormatTemp(temp).rjust(5, ' ')

    def getsensorhistformatted(self, id):
        s = self.__getsensor(id)
        temp = 0.0
        if 'temp' in s:
	    temp = s['trend'][0]
	    
	return self.sensorFormatTemp(temp).rjust(5, ' ')

    def getsensorstamp(self, id):
        s = self.__getsensor(id)
        if 'stamp' in s:
            return s['stamp']
        return '00:00:00'

    def getsensorsignal(self, id):
        s = self.__getsensor(id)
        if 'signal' in s:
            return str(s['signal'])
        return ' '

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
    
    def resettrend(self):
        for s in self.sensors:
	    t = self.sensors[s]['temp']	    
	    for i in range(0, self.trendsize):
                    self.sensors[s]['trend'][i] = t


def main():

    sensors = SensorList(trendsize=10)

if __name__ == "__main__":
    main()

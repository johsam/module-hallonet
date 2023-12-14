import drawille
import time
import json


class Graph(object):
    """This class implements the graph surface."""

    def __init__(self, w, h, m):
        super(Graph, self).__init__()
        self.clear()
        self.w = w
        self.h = h
        self.pw = (w * 2) - 0
        self.ph = (h * 4)
        self.m = m
        self.canvas = drawille.Canvas()

    def clear(self):
        self.data = []
        self.stamps = []
        self.normalized = []
        self.drows = []
        self.doAverage = True
        self.doLines = True
        self.doBresenham = True
        self.doTicks = True

    def toggleAverage(self):
        self.doAverage = not self.doAverage

    def toggleLines(self):
        self.doLines = not self.doLines

    def toggleBresenham(self):
        self.doBresenham = not self.doBresenham

    def getLines(self):
        return self.doLines

    def getAverage(self):
        return self.doAverage

    def getBresenHam(self):
        return self.doBresenham

    def rows(self):
        return self.drows

    def _bresenham_1(self, x0, y0, x1, y1):

    # implemented straight from WP pseudocode

        dx = x1 - x0
        if dx < 0:
                dx = -dx

        dy = y1 - y0
        if dy < 0:
                dy = -dy

        if x0 < x1:
                sx = 1
        else:
                sx = -1

        if y0 < y1:
                sy = 1
        else:
                sy = -1

        err = dx - dy

        while True:
            self._set(x0, y0)

            if x0 == x1 and y0 == y1:
                break

            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x0 += sx

            if e2 < dx:
                err += dx
                y0 += sy

    def _bresenham_2(self, x, y, x2, y2):
        """Brensenham line algorithm"""
        steep = 0
        coords = []
        dx = abs(x2 - x)
        dy = abs(y2 - y)

        if (x2 - x) > 0:
            sx = 1
        else:
            sx = -1

        if (y2 - y) > 0:
            sy = 1
        else:
            sy = -1

        if dy > dx:
            steep = 1
            x, y = y, x
            dx, dy = dy, dx
            sx, sy = sy, sx
        d = (2 * dy) - dx

        for i in range(0, dx):
            if steep:
                self._set(y, x)
            else:
                self._set(x, y)

            while d >= 0:
                y = y + sy
                d = d - (2 * dx)

            x = x + sx
            d = d + (2 * dy)
        self._set(x2, y2)

    def line(self, x1, y1, x2, y2):
        if y2 < 0:
            y2 = 0

        if (self.doBresenham):
            self._bresenham_1(
                drawille.normalize(x1),
                drawille.normalize(y1),
                drawille.normalize(x2),
                drawille.normalize(y2)
            )

        else:
            for x, y in drawille.line(x1, y1, x2, y2):
                self._set(x, y)

    def _set(self, x, y):
        self.canvas.set(x, y)

    def _debug(self, line):
        with open("/tmp/xxx", "a") as myfile:
            myfile.write(line)
        myfile.close()

    def _normalize(self):
        self.normalized = []
        self.miny = 10000.0
        self.maxy = -10000.0

        for d in self.data:
            if d > self.maxy:
                self.maxy = d
            if d < self.miny:
                self.miny = d

        if self.miny == self.maxy:
            self.maxy *= 1.05
            self.miny *= 0.95

        dy = float(self.maxy - self.miny)

        for d in self.data:
            if dy != 0.0:
                v = 1.0 - (float(d - self.miny) / dy)
            else:
            	v = 0.5
            self.normalized.append(v)

    def _formatFloat2(self, temp):
        return "{:.2f}".format(round(float(temp), 2))

    def _formatFloat1(self, temp):
        return "{:.1f}".format(round(float(temp), 1))

    def _drawlegend(self, nl):
        ltop = self._formatFloat1(self.maxy)
        lbottom = self._formatFloat1(self.miny)

        if nl < 2:
            ltop = ""
            lbottom = ""

        self.canvas.set_text(0, 0, ltop)
        self.canvas.set_text(0, self.ph - 4, lbottom)

    def _drawxtick(self, tx):
        ty = self.ph - 1
        self._set(tx, ty)
        self._set(tx, ty-1)

    def _drawxticks(self, t):
        tlen = len(t)

        #   Sort the ticks

        tk = sorted(t.keys())

        for i, x in enumerate(tk):
            if i == tlen / 2:
                stamp = time.strftime('%H:%M', time.localtime(float(t[x])))
                self.canvas.set_text(x - 4, self.ph - 4, stamp)
            self._drawxtick(x)

    def getlaststamp(self):
    	laststamp = 0
	sl = len(self.stamps)
	
	if sl > 0:
	    laststamp = self.stamps[sl - 1]
	return laststamp


    def box(self):
        rw = self.pw - 1
        rh = self.ph - 1
        self.line(0, 0, rw, 0)
        self.line(rw, 0, rw, rh)
        self.line(rw, rh, 0, rh)
        self.line(0, rh, 0, 0)

    def append(self, s, v):
        self.data.append(v)
        self.stamps.append(s)
        if len(self.data) > self.m:
            self.data.pop(0)
            self.stamps.pop(0)

    def draw(self):
        self.canvas.clear()
        self._normalize()

        nlen = len(self.normalized)
        self._drawlegend(nlen)

        if nlen > 1:
            transform = {}
            xticks = {}

            for x, d in enumerate(self.normalized):
                rx = int(round((x * (self.pw - 1)) / (nlen - 1)))
                ry = (d * (self.ph - 1 - 2))

                if rx not in transform:
                    transform[rx] = []
                transform[rx].append(ry)

                if self.doTicks is True:
                    tick = self.stamps[x]
                    tick5 = tick - (tick % 300)

                    if (tick5 % (3600 * 1)) == 0:
                        xticks[rx] = tick

            keys = sorted(transform.keys())

            # Get the first position

            lastx = 0
            lasty = newy = sum(transform[keys[0]]) / float(len(transform[keys[0]]))

            for i, newx in enumerate(keys):
                if i == 0:
                    continue

                dy = transform[newx]
                if self.doAverage is True:
                    newy = sum(dy) / float(len(dy))
                else:
                    newy = dy[len(dy) - 1]

                if self.doLines is True:
                    self.line(lastx, lasty, newx, newy)
                else:
                    self._set(newx, newy)

            	lastx = newx
            	lasty = newy

            if self.doTicks is True:
                self._drawxticks(xticks)

        self.drows = self.canvas.rows()

        return

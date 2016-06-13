import drawille
import time


class Graph(object):
    """This class implements the graph surface."""

    def __init__(self, w, h, m):
        super(Graph, self).__init__()
        self.clear()
        self.w = w
        self.h = h
        self.pw = (w * 2) - 0
        self.ph = h * 4
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

    def _bresenham(self, x, y, x2, y2):
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
            self._bresenham(
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
        self.miny = 1000
        self.maxy = -1000

        for d in self.data:
            if d > self.maxy:
                self.maxy = d
            if d < self.miny:
                self.miny = d

        if self.miny == self.maxy:
            self.maxy *= 1.05
            self.miny *= 0.95

        dy = float(self.maxy - self.miny)
        if dy == 0.0:
            dy = 1.0

        for d in self.data:
            v = 1.0 - (float(d - self.miny) / dy)
            self.normalized.append(v)

    def _formatFloat2(self, temp):
        return "{:.2f}".format(round(float(temp), 2))

    def _formatFloat1(self, temp):
        return "{:.1f}".format(round(float(temp), 1))

    def _drawxtick(self, tx):
        ty = self.ph - 1
        self._set(tx, ty)
        self._set(tx, ty-1)

    def _drawlegend(self, nl):
        ltop = self._formatFloat1(self.maxy)
        lbottom = self._formatFloat1(self.miny)

        if nl < 2:
            ltop = ""
            lbottom = ""

        self.canvas.set_text(0, 0, ltop)
        self.canvas.set_text(0, self.ph - 4, lbottom)

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
            lastx = 0
            deltay = []
            px = 0.0
            py = 0.0

            for x, d in enumerate(self.normalized):
                rx = (x * (self.pw - 1)) / (nlen - 1)
                ry = d * (self.ph - 1)

                if self.doTicks is True:
                    tick = self.stamps[x]
                    tick5 = tick - (tick % 300)

                    if (tick5 % (3600 * 1)) == 0:
                        self._drawxtick(rx)

                if int(rx) == self.pw / 2:
                    stamp = time.strftime('%H:%M', time.localtime(float(self.stamps[x])))
                    self.canvas.set_text(rx - 4, self.ph - 4, stamp)

                if int(rx) != lastx:

                    if len(deltay) == 0:
                            deltay.append(ry)

                    if self.doAverage is True:
                        dy = sum(deltay) / float(len(deltay))
                    else:
                        dy = deltay[0]

                    if self.doLines is True and rx != 0.0 and lastx != 0.0:
                        self.line(px, py, lastx, dy)
                    else:
                        self._set(lastx, dy)

                    px = lastx
                    py = dy

                    lastx = rx
                    deltay = []
                else:
                    deltay.append(ry)

            #   And the last point

            if self.doLines is True:
                self.line(px, py, lastx, dy)
            else:
                self._set(rx, ry)

        self.drows = self.canvas.rows()

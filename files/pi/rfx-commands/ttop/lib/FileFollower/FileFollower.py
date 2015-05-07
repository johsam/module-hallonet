import threading
import time


def synchronized(lock):
    """ Synchronization decorator """
    def wrap(f):
        def newfunction(*args, **kw):
            with lock:
                return f(*args, **kw)
        return newfunction
    return wrap


class FileFollower (threading.Thread):
    def __init__(self, filename, queue, interval=1.0):
        threading.Thread.__init__(self)
        self._interval = interval
        self._filename = filename
        self._stop = False
        self._queue = queue
        self._file = open(self._filename, 'r')

        # Seek to the end
        self._file.seek(0, 2)

    def stop(self):
        self._stop = True

    def run(self):
        for line in self._tail_f(self._file):
            self._queue.put(line.rstrip())
            if self._stop:
                break

    def _tail_f(self, file):

        while not self._stop:
            where = file.tell()
            line = file.readline()
            if not line:
                time.sleep(self._interval)
                file.seek(where)
            else:
                yield line


def main():
    exit(0)

if __name__ == "__main__":
    main()

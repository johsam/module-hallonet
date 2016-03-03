#!/usr/bin/env python

import sys
import time
import argparse
import os
import json
import syslog
from daemon import Daemon
from pubnub import Pubnub
import subprocess


class MyDaemon(Daemon):

    def createfile(self, filename):
        open(filename, 'a').close()

    def removefile(self, filename):
        if os.path.exists(filename):
            os.remove(filename)

    def error(self, message, channel):
        syslog.syslog(syslog.LOG_ERR, "Error " + message)

    def send_message(self, channel, message):
        self.pubnub.publish(channel, {"type": "message", "message": message})
    	syslog.syslog("Sent '" + message + "' to channel (" + channel + ")")

    def call_command(self, info, command, feedback=False):

        try:
            syslog.syslog("Calling '" + command + "'")
            result = subprocess.check_output(command, stderr=subprocess.STDOUT, shell=True)
            syslog.syslog("Done processing external script")
            if feedback is True:
            	self.send_message(args.pubnub_channel + "-sensors", "Excuted: '" + command + "'")

        except subprocess.CalledProcessError as e:
            msg = "Output from command was '" + e.output.rstrip('\n') + "' exitcode=" + str(e.returncode)
            syslog.syslog(syslog.LOG_WARNING, msg)
            self.send_message(args.pubnub_channel + "-sensors", msg)
        pass

    #
    #   Message from pubnub received
    #

    def callback(self, message, channel):

        if type(message) != type(dict()):
            syslog.syslog("Channel '%s': Unsupported type (%s)" % (channel, type(message)))
            return

        if not 'type' in message:
            syslog.syslog("Channel '%s': 'type' not found in message (%s)" % (channel, json.dumps(message)))
            return

        if not 'info' in message:
            syslog.syslog("Channel '%s': 'info' not found in message (%s)" % (channel, json.dumps(message)))
            return

        info = message['info']

        #
        # Request ?
        #

        if message['type'] == 'request' and 'request' in message:

            request = message['request']

            if not 'action' in request:
                syslog.syslog("Channel '%s': 'action' not found in message (%s)" % (channel, json.dumps(message)))
                return

            if not 'target' in request:
                syslog.syslog("Channel '%s': 'target' not found in message (%s)" % (channel, json.dumps(message)))
                return

            action = request['action']
            target = request['target']
            command = ''

            if action == 'restart':
                if target == 'rfxcmd':
                    command = "/usr/sbin/service rfxcmd restart"

                if target == 'openhab':
                    command = "/usr/sbin/service openhab restart"

                if target == 'hallonet':
                    command = "/sbin/reboot"

                if len(command):
                    syslog.syslog("Channel '%s': %s -> %s" % (channel, action, target))
                    self.call_command(info, command)

                else:
                    syslog.syslog("Channel '%s': Unknown target '%s' for action '%s' (%s)" % (channel, target, action, json.dumps(message)))

        #
        # Status ?
        #

        if message['type'] == 'status' and 'status' in message:

            status = message['status']
            state = status['state']

            ip = info['ip']
            application = info['application']
            version = info['version']

            # Only hallonet for now

            if application == 'hallonet':
                if state == 'started':
                    self.createfile(args.publish_temp_file)
                elif state == 'stopped':
                    self.removefile(args.publish_temp_file)

            syslog.syslog("Channel '%s': %s[%s] (%s) from %s" % (channel, application, version, state, ip))

        #
        # Switch ?
        #

        if message['type'] == 'switch' and 'switch' in message:

            switch = message['switch']

            if not 'nexaid' in switch:
                syslog.syslog("Channel '%s': 'nexaid' not found in message (%s)" % (channel, json.dumps(message)))
                return

            if not 'state' in switch:
                syslog.syslog("Channel '%s': 'state' not found in message (%s)" % (channel, json.dumps(message)))
                return

            state = switch['state']
            nexaid = switch['nexaid']
            command = "/home/pi/rfx-commands/commands/cmd-to-nexa.sh %s %s" % (nexaid, state)

            syslog.syslog("Channel '%s': %s -> %s -> %s" % (channel, "switch", nexaid, state))
            self.call_command(info, command)

    def run(self):

        self.pubnub = Pubnub(
            publish_key=args.pubnub_pubkey,
            subscribe_key=args.pubnub_subkey,
            secret_key='',
            cipher_key='',
            ssl_on=False
            )
    	syslog.openlog(logoption=syslog.LOG_PID, facility=syslog.LOG_DAEMON)
        syslog.syslog("Listening on Channel '%s'" % args.pubnub_channel)
        self.pubnub.subscribe(args.pubnub_channel, self.callback)


if __name__ == "__main__":

    #
    # Parse arguments
    #

    parser = argparse.ArgumentParser(description='Simple daemon for pubnub')

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
        '--pid-file', required=True,
        default='',
        dest='pid_file',
        help='Pid file'
    )

    parser.add_argument(
        '--allow-publish-file', required=True,
        default='',
        dest='publish_temp_file',
        help='Status file'
    )

    parser.add_argument(
        '--start', required=False,
        default=False,
        dest='do_start',
        action='store_true'
    )

    parser.add_argument(
        '--stop', required=False,
        default=False,
        dest='do_stop',
        action='store_true'
    )

    parser.add_argument(
        '--status', required=False,
        default=False,
        dest='do_status',
        action='store_true'
    )

    parser.add_argument(
        '--restart', required=False,
        default=False,
        dest='do_restart',
        action='store_true'
    )

    args = parser.parse_args()

    daemon = MyDaemon(args.pid_file)

    if args.do_start is True:
        syslog.syslog("Starting...")
        daemon.start()

    elif args.do_stop is True:
        syslog.syslog("Stopping...")
        daemon.removefile(args.publish_temp_file)
        daemon.stop()

    elif args.do_status is True:
        daemon.is_running()

    elif args.do_restart is True:
        syslog.syslog("Restarting...")
        daemon.restart()

    else:
        print "usage: %s start|stop|restart" % sys.argv[0]
        sys.exit(2)

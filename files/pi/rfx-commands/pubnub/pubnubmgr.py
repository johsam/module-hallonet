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
        open(filename,'a').close()


    def removefile(self, filename):
        if os.path.exists(filename):
    	    os.remove(filename)
    
    def error(self, message, channel):
	syslog.syslog("Error " + message)

    def callback(self, message, channel):
       	
	if type(message) == type(dict()):
	    
	    #
	    # Request ? 
	    #
	    
	    if 'type' in message and message['type'] == 'request' and 'request' in message:
		 
		 requesttype = message['request']
		 syslog.syslog("Channel %s: %s -> %s" % (channel, "request", json.dumps(message['request'])))
                 
		 histlen=5
		 if "length" in message['request']:
		 	histlen = message['request']['length']
		 
		 syslog.syslog("Calling '" + args.external_history + " " + str(histlen) + "'")
		 jsonstr = subprocess.check_output([args.external_history,str(histlen)], stderr=subprocess.STDOUT)
		 syslog.syslog("Done processing external script")
		 
		 try:
		 	js = json.loads(jsonstr)
		 	self.pubnub.publish(args.pubnub_channel, js)
		 except:
		 	syslog.syslog("Failed to parse json from script -> '" + jsonstr + "'")
		  
	    #
	    # Status ?
	    #
	    

	    if 'type' in message and message['type'] == 'status' and 'status' in message:
	       
	       status = message['status']
	       
	       ip = status['ip']
	       state = status['state']
	       application = status['application']
	
	       # Only hallonet for now
	       
	       if application == 'hallonet':
	           if state == 'started':
	              self.createfile(args.publish_temp_file)
	           elif state == 'stopped':
	              self.removefile(args.publish_temp_file)
		    		   
	       syslog.syslog("Channel %s: %s (%s) from %s" % (channel, application, state, ip))
	else:
               syslog.syslog("Channel %s: Unsupported type (%s)" % (channel,type(message)))

    def run(self):

        self.pubnub = Pubnub(publish_key=args.pubnub_pubkey,
                        subscribe_key=args.pubnub_subkey,
                        secret_key='',
                        cipher_key='',
                        ssl_on=False
                        )
        syslog.syslog("Listening on Channel %s" % args.pubnub_channel)
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
        '--external-history', required=True,
        default='',
        dest='external_history',
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

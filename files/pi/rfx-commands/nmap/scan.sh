#!/bin/bash

#---------------------------------------------------------------------
#
#	Created by: Johan Samuelson - Diversify - 2014
#
#	$Id:$
#
#	$URL:$
#
#---------------------------------------------------------------------

######################################################################
#
#	Catch signals...
#
######################################################################

trap 'rm -f "${tmpfile}" > /dev/null 2>&1' 0
trap "exit 2" 1 2 3 15

######################################################################
#
#	Setup variables...
#
######################################################################

tmpfile="/tmp/`basename $0`-$$.tmp"


[ -h "$0" ] && scriptDir=$(dirname `readlink $0`) || scriptDir=$( cd `dirname $0` && pwd)

#
# Can we create our lock file ?
#

[ ! -w /var/lock/ ] && { logger -t "$(basename $0)" "Could not create lock file '/var/lock/nmap.lock'"; exit 1;}

#
#	Use flock to prevent multiple executions
#

umask 011

(
flock -x -w 120 300 || { logger -t "$(basename $0)" "Failed to aquire lock for nmap"; exit 1; }
python ${scriptDir}/scan.py
) 300> /var/lock/nmap.lock

exit 0

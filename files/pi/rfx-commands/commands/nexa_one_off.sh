#!/bin/bash

umask 0011

ipaddress=$(/usr/bin/facter ipaddress)

printf "$(date '+%F %T')\tsend\t(${1} -> off)\n" >> /var/rfxcmd/nexa-setstate.log

/opt/rfxcmd/rfxsend.py -s ${ipaddress} -r "0B11000000D813320${1}000000"

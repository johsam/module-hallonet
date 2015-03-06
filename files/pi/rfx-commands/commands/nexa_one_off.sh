#!/bin/bash

umask 022

printf "$(date '+%F %T')\tsend\t(${1} -> off)\n" >> /var/rfxcmd/nexa-setstate.log

/opt/rfxcmd/rfxsend.py -s 192.168.1.48 -r "0B11000000D813320${1}000000"

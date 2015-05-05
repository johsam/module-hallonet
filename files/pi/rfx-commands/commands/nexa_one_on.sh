#!/bin/bash

umask 0011

ipaddress=127.0.0.1

printf "$(date '+%F %T')\tsend\t(${1} -> on)\n" >> /var/rfxcmd/nexa-setstate.log

/opt/rfxcmd/rfxsend.py -s ${ipaddress} -r "0B11000000D813320${1}010F00"

exit 0

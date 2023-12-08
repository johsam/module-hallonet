#!/bin/bash

tail -1 /var/rfxcmd/sensor.csv | grep -E "^Error:" > /dev/null ; status=$?

if [ ${status} -eq 0 ] ; then
    date >> /var/rfxcmd/reset-rfx.log
    /etc/init.d/rfxcmd restart >> /var/rfxcmd/reset-rfx.log
fi

exit 0
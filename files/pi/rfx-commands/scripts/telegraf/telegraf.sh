#!/bin/bash

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
core_temp_raw=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp)
core_temp=$(python -c 'import sys;print u"{:.1f}".format(float(sys.argv[1]) / 1000.0).encode("utf-8")' ${core_temp_raw})

echo "pi,host=$(uname -n),type=sensor,measurement=temp,id=cpu_core value=${core_temp}"

exit 0

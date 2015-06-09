#!/bin/sh

host=$(hostname)
now="$(date +%s)"
core_temp=$(cat /sys/devices/virtual/thermal/thermal_zone0/temp | awk '{printf("%.2f",$0 / 1000.0)};')
path="linux.${host}.cpu.core.temp ${core_temp} ${now}"

echo $path | nc -q0 mint-black 2003

exit 0

#!/bin/sh

multitail -du  \
	-wh 2 /var/log/WiFi_Check.log \
	-wh 3 /var/rfxcmd/reset-rfx.log \
	/var/rfxcmd/update-rest.log \
	-wh 4 /var/rfxcmd/temperatur-nu.log \
	-wh 6 /var/rfxcmd/sensor.csv

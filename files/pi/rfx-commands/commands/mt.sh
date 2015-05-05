#!/bin/sh

multitail -du  \
	-wh 4 /var/log/WiFi_Check.log \
	-wh 4 /var/rfxcmd/openhab-status.log \
	/var/rfxcmd/update-rest.log \
	-wh 6 /var/rfxcmd/temperatur-nu.log \
	-wh 8 /var/rfxcmd/sensor.csv

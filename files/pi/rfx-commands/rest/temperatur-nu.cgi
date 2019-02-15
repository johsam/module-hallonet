#!/bin/bash

echo "Content-type: application/json"
echo ""


echo "{\"temperature\":$(cat /var/rfxcmd/statics/temperatur.txt)}"

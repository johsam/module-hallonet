#!/bin/bash

(
clear
export TERM=xterm-256color

#	Move window

#printf '\e[3;0;0t'

# Resize window

printf "\e[8;14;35t"

/home/pi/rfx-commands/ttop/ttop.py
)

exit 0

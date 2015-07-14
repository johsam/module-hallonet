#!/bin/bash

(
clear
export TERM=xterm-256color
source /home/pi/rfx-commands/settings.cfg

#	Move window

#printf '\e[3;0;0t'

# Resize window

printf "\e[8;20;56t"

/home/pi/rfx-commands/ttop/ttop.py --pubnub-subkey "${PUBNUB_SUBKEY}" --pubnub-pubkey "${PUBNUB_PUBKEY}" --pubnub-channel "${PUBNUB_CHANNEL}"
)

exit 0

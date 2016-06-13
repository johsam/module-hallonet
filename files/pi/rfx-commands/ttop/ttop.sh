#!/bin/bash

(
clear
export TERM=xterm-256color
source /home/pi/rfx-commands/settings.cfg


mysql tnu -urfxuser -prfxuser1 --skip-column-names  \
    -e 'select UNIX_TIMESTAMP(datetime),temp from tnu where datetime >= (now() - INTERVAL 24 HOUR) order by datetime desc;' | tac | tail -500000 > /tmp/seed.log


#	Move window

#printf '\e[3;0;0t'

# Resize window

printf "\e[8;30;58t"

/home/pi/rfx-commands/ttop/ttop.py \
    --pubnub-subkey "${PUBNUB_SUBKEY}" \
    --pubnub-pubkey "${PUBNUB_PUBKEY}" \
    --pubnub-channel "${PUBNUB_CHANNEL}" \
    --seed /tmp/seed.log \
    --max-vals $((145 * 1))
)
 
exit 0

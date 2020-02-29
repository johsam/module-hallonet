#!/bin/bash

logger -t $(basename $0) "Start check for updates"

(
sudo apt update
#aptitude search '~U' > /tmp/$(uname -n)-updates.txt
apt list --upgradable | grep -vi "^Listing..." > /tmp/$(uname -n)-updates.txt
) > /tmp/check-apt.err 2>&1

logger -t $(basename $0) "Done..."

exit 0

#!/bin/bash

(
sudo apt-get update
aptitude search '~U' > /tmp/$(uname -n)-updates.txt
) > /dev/null 2>&1
exit 0

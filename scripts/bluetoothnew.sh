#!/bin/bash
read mac | cat ~/blmac.txt
bluetoothctl connect $mac | grep "Successful"
echo "Connected to your headphones"
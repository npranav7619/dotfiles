#!/bin/bash

echo "Enter the brightness value : "
read bri
xrandr --output eDP --brightness "$bri" 
echo "Success"

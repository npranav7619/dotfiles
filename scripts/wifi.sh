#!/bin/bash
nmcli d wifi list
echo "Enter wifi name : "
read name
echo "Enter password : "
read pass
nmcli device wifi connect $name password $pass
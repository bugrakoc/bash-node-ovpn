#!/bin/bash
#
# https://github.com/bugrakoc/bash-node-ovpn
#
# Bash script for node.js - openvpn integration

result () {}

if [[ -e /etc/debian_version ]]; then
	OS=debian
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	echo "This needs to run on Debian or CentOS"
	exit
fi

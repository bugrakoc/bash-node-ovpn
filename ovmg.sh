#!/bin/bash
#
# https://github.com/bugrakoc/bash-node-ovpn
# Copyright (c) 2018 Bugra Koc
# Released under GNU General Public License v3
#
# Bash script for adding and revoking OpenVPN users.
# Should work on Debian and Redhat derivatives.
# Needs root privileges.
#
# Flags
# -a <name> : Add a new user named <name>
# -l        : List all users
# -r <name> : Revoke user <name>
#

if readlink /proc/$$/exe | grep -q "dash"; then
    echo "ovmg.sh needs to run with bash."
    exit
fi

if [[ "$EUID" -ne 0 ]]; then
    echo "ovmg.sh needs to run as root."
    exit
fi

if [[ -e /etc/debian_version ]]; then
    OS=debian
    GROUPNAME=nogroup
    RCLOCAL='/etc/rc.local'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
    OS=centos
    GROUPNAME=nobody
    RCLOCAL='/etc/rc.d/rc.local'
else
    echo "ovmg.sh only runs on Debian or Redhat."
    exit
fi

mode=""
name=""
arg_count=0

# Get the flags inside the variables
while getopts 'a:r:l' flag; do
  case "${flag}" in
    a)
        mode="add"
        name="${OPTARG}"
        arg_count=$arg_count+1
        if (($arg_count > 1)); then
            echo "supply only one flag"
            exit
        fi
    ;;
    r)
        mode="revoke"
        name=${OPTARG}
        arg_count=$arg_count+1
        if (($arg_count > 1)); then
            echo "supply only one flag"
            exit
        fi
    ;;
    l)
        mode="list"
        arg_count=$arg_count+1
        if (($arg_count > 1)); then
            echo "supply only one flag"
            exit
        fi
    ;;
    *) echo "invalid argument"
    exit ;;
  esac
done

# List users, or add/revoke user
if [[ $mode = "add" ]]; then
    echo "ADDING $name"
    cd /etc/openvpn/easy-rsa/
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full $name nopass
    # Output the custom client.ovpn
    cat /etc/openvpn/client-common.txt
	echo "<ca>"
	cat /etc/openvpn/easy-rsa/pki/ca.crt
	echo "</ca>"
	echo "<cert>"
	cat /etc/openvpn/easy-rsa/pki/issued/$name.crt
	echo "</cert>"
	echo "<key>"
	cat /etc/openvpn/easy-rsa/pki/private/$name.key
	echo "</key>"
	echo "<tls-auth>"
	cat /etc/openvpn/ta.key
	echo "</tls-auth>"
    exit
elif [[ $mode = "revoke" ]]; then
    echo "REVOKING $name"
    NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
	if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
		echo "you have zero clients"
        exit
	fi
	cd /etc/openvpn/easy-rsa/
	./easyrsa --batch revoke $name
	EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
	rm -f pki/reqs/$name.req
	rm -f pki/private/$name.key
	rm -f pki/issued/$name.crt
	rm -f /etc/openvpn/crl.pem
	cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
	# CRL is read with each client connection, when OpenVPN is dropped to nobody
	chown nobody:$GROUPNAME /etc/openvpn/crl.pem
    echo "privileges for $name revoked"
	exit
elif [[ $mode = "list" ]]; then
    tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2
    exit
else
    echo "invalid argument"
    exit
fi

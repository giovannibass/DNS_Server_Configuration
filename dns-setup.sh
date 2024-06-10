#!/bin/bash
#
# Created by Giovanni Bass
# The purpose of this script is to speed up the process of setting upp a DNS Server.
# Currently this script supports customizing the listening address, query addresses, and domain name.


# Usage function
usage() {
	echo "Usage: ${0} [-lqd]
	[-l Address the DNS server should listen on]
	[-q Address or subnet the DNS server should respond to]
	[-d Name of the domain]"
			exit 1
}

# Function to ensure the domain has an appropiate TLD ending
tld_check() {
	if [[ ! "$1" =~ \.[a-zA-Z]{2,}$ ]]; then
		echo "Error! Your domain name must have a top-level domain ending (.com, .org, .net, etc.)"
		exit 1
	fi
}

# Variables to check if options were selected.
LISTENING_IP_CHECK=0
QUERY_CHECK=0
DOMAIN_NAME_CHECK=0

# Command line options.
while getopts "l:q:d:" opt; do
	case ${opt} in
		l)
			LISTENING_IP=$OPTARG
			LISTENING_IP_CHECK=1
			;;
		q)
			QUERY=$OPTARG
			QUERY_CHECK=1
			;;
		d)
			DOMAIN_NAME=$OPTARG
			DOMAIN_NAME_CHECK=1
			tld_check "${DOMAIN_NAME}"
			;;
		?)
			usage
			''
		esac
done

# Check if the user has root privileges.
if [[ ${UID} -ne 0 ]]
then
	echo "You need to have root privileges to run this script!" >&2
	exit 1
fi

# Check if all required options are provided
if [[ $LISTENING_IP_CHECK -eq 0 || $QUERY_CHECK -eq 0 || $DOMAIN_NAME_CHECK -eq 0 ]]
then
	echo "Error: Missing required options."
	usage
fi

# Check to see if the named service has already been installed.
systemctl list-unit-files | grep ^named.service$

# If bind hasn't been installed, then install it.
if [[ ${?} -eq 0 ]]
then
	echo "[-] The service 'named' has already been installed."
else
	echo "[-] The service 'named' has not been installed. Attempting to install now."
	sudo yum install bind bind-utils
fi

# Make sure to backup existing named.conf file before beginning configuration.
sudo cp /etc/named.conf /etc/named.conf-backup

# Create the configuration file for the domain
sudo bash -c cat > /etc/named.conf << EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//

options {
	listen-on port 53 { 127.0.0.1; ${LISTENING_IP}; };
	listen-on-v6 port 53 { ::1; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	secroots-file	"/var/named/data/named.secroots";
	recursing-file	"/var/named/data/named.recursing";
	allow-query     { localhost; ${QUERY}; };

	/*
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable
	   recursion.
	 - If your recursive DNS server has a public IP address, you MUST enable access
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface
	*/
	recursion yes;

	dnssec-validation yes;

	managed-keys-directory "/var/named/dynamic";
	geoip-directory "/usr/share/GeoIP";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";

	/* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
	include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "example.com" IN {
       type master;
       file "example.com.zone";
       allow-update { none; };
   };

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

# Create a zone file for the domain
echo "[-] Creating zone file for ${DOMAIN_NAME}"

sudo bash -c cat > /var/named/${DOMAIN_NAME}.zone << EOF
\$TTL 86400
@ IN SOA ns1.${DOMAIN_NAME}. admin.${DOMAIN_NAME}. ( 
  2024060501 ; Serial
  3600       ; Refresh
  1800       ; Retry
  604800     ; Expire
  86400      ; Minimum TTL
)
IN NS ns1.${DOMAIN_NAME}.
ns1 IN A 192.168.1.1
@       IN  A       192.168.1.10
ns1     IN  A       192.168.1.10
www     IN  A       192.168.1.10
EOF

if [[ ${?} -ne 0 ]]
then
	echo "[x] The zone file for ${DOMAIN_NAME} could not be created."
	exit 1
else
	echo "[-] The zone file for ${DOMAIN_NAME} has been created in /var/named."
fi

# Check to see if DNS traffic has been allowed by the firewall.
firewall-cmd --list-services | grep ^dns$

if [[ ${?} -ne 0 ]]
then
	echo "[x] The firewall has not been configured to allow DNS services."
	echo "[-] Enabling firewall changes now..."
	sudo firewall-cmd --add-service=dns --permanent
	echo "[-] Firewall settings have been completed. Reloading the firewall configuration..."
	sudo firewall-cmd --reload
	echo "[-] Process complete."
else
	echo "[-] Firewall already allows DNS traffic."
fi

# Start/enable the named service
echo "[-] Starting the named service..."
sudo systemctl start named
echo "[-] Enabling the named service..."
sudo systemctl enable named
echo "[-] The configuration of ${DOMAIN_NAME} has been completed!"

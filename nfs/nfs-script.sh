#!/bin/bash

# Script for quickly setting up an NFS server.
# 
#
# This is not designed for thorough NFS configuration. As of right now you can customize the directory and the IP/subnet clients need to be connected to in order to access the share.
#
# Created by Giovanni Bass II


# Usage fucntion
usage() {
echo "Usage: $0 [-d DIRECTORY] [-a ACCESS]"
exit 1
}

# Function to check if a command was properly executed
check() {
if [[ ${?} -ne 0 ]]
then
	echo "[x] Error: $1 failed."
	exit 1
fi
}

# Check if the user is running the script with root privileges
if [[ ${UID} -ne 0 ]]
then
	echo "[!] You need root privileges in order to run this script!"
	exit 1
fi

# Command line options
while getopts "d:a:" OPTION
do
	case "${OPTION}" in
		d) DIRECTORY=${OPTARG};;
		a) ACCESS=${OPTARG};;
		?) usage;;
	esac
done

# Debugging statement to check the value of DIRECTORY
# echo "DIRECTORY after getopts: '${DIRECTORY}'"

# Setting default directory if one was not specified
if [[ -z ${DIRECTORY} ]]
then
	DIRECTORY=$(pwd)/nfs_share
	echo "[-] No directory specified. Using current one: ${DIRECTORY}"
else
	echo "[-] Using directory: ${DIRECTORY}"
fi

# Set default access if not provided
if [[ -z ${ACCESS} ]]
then
	ACCESS="*"
	echo "[!] No access specified. Using default: $ACCESS"
fi

# Check if NFS Server packages have been installed. If not, install them.
if ! rpm -q nfs-utils &> /dev/null; then
	echo "[-] NFS Utilities not found. Installing now..."
	sudo yum install nfs-utils -y
else
	echo "[-] NFS Utilities has been found."
fi

# Check to see if the specified directory exists. Create the directory to be shared
if [[ -d ${DIRECTORY} ]]
then
	echo "[!] Directory ${DIRECTORY} already exists."
else
	echo "[-] Creating directory to be shared."
	mkdir -p ${DIRECTORY}
	check "[x] Creating ${DIRECTORY}"
fi

# Setting directory permissions
echo "[-] Setting permissions for directory"
chown nobody:nobody "${DIRECTORY}"
check "[x] Configuring ownership permissions has"
chmod 755 "${DIRECTORY}"
check "[x] Configuring directory permissions has"

# Create a backup of the exports file and then configure the original. If the exports file does not exist, create it.
if [[ ! -f /etc/exports ]]
then
	echo "[!] /etc/exports does not exist. Creating it..."
	touch /etc/exports
	check "[x] Creation of /etc/exports has"
else
	echo "[-] Backing up /etc/exports under /etc/exports.bak"
	sudo cp -p /etc/exports /etc/exports.bak
	check "[x] Backup of /etc/exports"
fi

echo "[-] Configuring NFS exports"
echo "${DIRECTORY} ${ACCESS}(rw,sync,no_subtree_check)" >> /etc/exports

# Export the shared directory
echo "[-] Exporting the shared directory..."
exportfs -rav | grep -w ${DIRECTORY}
check "[x] Exporting the shared directory has"
echo "[-] ${DIRECTORY} has been exported and is ready for use!"

# Start and enable the NFS server
sudo systemctl start nfs-server
check "[x] Starting the NFS server service has"
sudo systemctl enable nfs-server
check "[x] Starting the NFS server service has"


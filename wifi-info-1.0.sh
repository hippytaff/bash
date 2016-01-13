#!/bin/bash

# Change log

# Version 1.0
# Date 20/12/15
# written by hippytaff and matt_symes

################################################################################################
# Script description
################################################################################################

# Script arguments
# --verbose. Verbose output from continual monitoring.

################################################################################################
# script defines
################################################################################################

# Defines for the script.
VERBOSE=1
QUIET=0
WLESS=wireless-results.txt
VERSION=1.0
DATE_FN=
WHOAMI=
ROUTE=
PING=
NSLOOKUP=
WGET=
PGREP=
IFCONFIG=
DHCP=
PING_TRIES=3
REPING_TIME=0.2
ROUTER_PING_TARGET=	 	
EXTERNAL_PING_TARGET=8.8.8.8
DNS_LOOKUP_NAME=www.google.com
WGET_URL=www.google.com
PING_TARGETS=("8.8.8.8" "8.8.4.4" "156.154.70.1" "156.154.71.1" "208.67.222.222" "208.67.220.220" "198.153.194.1" "4.2.2.1" "4.2.2.2" "4.2.2.3" "4.2.2.4" "4.2.2.5" "4.2.2.6")
URL_TARGETS=("ubuntuforums.org" "www.google.com" "www.amazon.com" "www.microsoft.com" "www.slashdot.com" "www.bbc.co.uk" "www.askgeeves.co.uk" "www.ebay.com" "www.yahoo.com" "www.aol.com")
NETWORK_MANAGER=[N]etworkManager
WPA_NAME=[w]pa_supplicant
PGREP_WICD_PID=
PGREP_NM_PID=
WICD=wicd
WLAN_NAME=
WLAN_DRIVER=
WLAN_IP=
VERBOSE_CONNECTIVITY_CHECKING=
RESOLV_FILE=/etc/resolv.conf
INTERFACES_FILE=/etc/network/interfaces
MODULES_FILE=/etc/modules
BLACKLIST_FILE=/etc/modprobe.d/blacklist.conf
BLACKLIST_FOLDER=/etc/modprobe.d/*
SYSLOG_LOG=/var/log/syslog
MESSAGES_LOG=/var/log/messages
KERNEL_LOG=/var/log/kern.log
NM_STATE_FILE=/var/lib/NetworkManager/NetworkManager.state
NM_APPLET_FILE=/etc/NetworkManager/nm-system-settings.conf

#################################################################################################
# functions
#################################################################################################
# Function to redirect stdout to wireles-script.txt ($WLESS)
call_redirect_stdout() {

	# Redirect output.
	exec 5>&1
	exec >> "$WLESS"
	exec 2>&1
}
# Function to restore stdout
call_restore_stdout() {

	exec 1>&5 5>&-
}

# Function to check for that we havve root privilages#
call_check_root_privilages() {

	WHOAMI=$(which whoami)

	[[ "$WHOAMI" == "" ]] && { echo "Cannot find whoami binary"; exit 1; }

	# Check we are root.
	[[ $("$WHOAMI") == "root" ]] ||
		{ echo "This script needs to be run as root. Please run with sudo ./wireless_script"; exit 1; }
}

# Function to initialise the script
call_initialise() {

	# Get the location of the 
	ROUTE=$(which route)
	PING=$(which ping)
	NSLOOKUP=$(which nslookup)
	WGET=$(which wget)
	PGREP=$(which pgrep)
	DATE_FN=$(which date)
	IFCONFIG=$(which ifconfig)
	DHCP=$(which dhclient)

	# Check binaries exist.
	# NOTE TO SELF. MAYBE SKIP WGET TEST IF BINARY NOT THERE.
	[[  "$ROUTE" != "" && "$PING" != "" &&
		"$NSLOOKUP" != "" && "$WGET" != "" && "$PGREP" != "" &&
		"$DATE_FN" != "" && "$IFCONFIG" != "" && "$DHCP" != "" ]] ||
		{ echo "cannot find required binaries"; exit 1; }

	sleep 1
}

# Function to check to see what networking daemons are running
call_check_for_running_network_daemons() {

	echo "***********************************************************************************************"
	echo "Running networking services"
	echo "***********************************************************************************************"
	
	# Get the pid for network manager
	PGREP_NM_PID=$("$PGREP" -fx "$NETWORK_MANAGER")

	# Check for a running instance of network manager or networking. Could attempt to start if not running ?
	if [[ "$?" -eq 0 ]]
	then
		if [[ $PGREP_NM_PID != "" ]] 
		then
			echo "NetworkManager is running"

			return 0
		else
			echo "NetworkManager is _not_ running"
		fi
	else
		echo "NetworkManager is _not_ running"
	fi

	# No network manager ? Check for wicd.
	PGREP_WICD_PID=$("$PGREP" -fx "$WICD")

	if [[ "$?" -eq 0 ]]
	then
		if [[ $PGREP_WICD_PID != "" ]]
		then
			echo "WICD is running"

			return 0
		else
			echo "WICD is _not_ running"
		fi
	else
		echo "WICD is _not_ running"
	fi

	# Check to see that networking is up.

	return 0;
}

# Function to aquire the system info for the network
call_get_system_info() {

	echo "************************************"
	echo "        Ubuntu release "
	echo "************************************"
	echo
	cat /etc/lsb-release
	echo
	echo "************************************"
	echo "        Kernel"
	echo "************************************"
	echo
	uname -a
	echo "************************************"
	echo "          List of drivers"
	echo "************************************"
	echo
	lsmod

	return 0
}

# Function to get the network info.
call_get_network_info() {

	echo
	echo "************************************"
	echo "        pci wireless devices"
	echo "************************************"
	echo
	lspci -nnk | grep -i -A3 wirel
	echo
	echo "************************************"
	echo "        usb wireless devices"
	echo "************************************"
	echo
	lsusb | grep -i wirel
	echo
	echo "************************************"
	echo "        List of network devices"
	echo "************************************"
	echo
	sudo lshw -C Network
	echo
	sleep 3 #wait for 3 seconds
	echo
	echo "************************************"
	echo "           network info"
	echo "************************************"
	echo
	ifconfig -v -a
	echo
	echo "************************************"
	echo " Wireless specific network info"
	echo "************************************"
	echo
	iwconfig
	echo "************************************"
	echo " Rfkill Blocks"
	echo "************************************"
	echo
	sudo rfkill list all
	echo
	echo "************************************"

	return 0
}

# Function to parse
call_parse_lshw_network() {

	# Get the network hardware details.
	LSHW_RES=$(sudo lshw -C Network)

	[[ "$?" -ne 0 ]] && { echo "Could not get lshw network information for parsing"; return 1; }

	# sleep for 3 seconds.
	sleep 3

	# Get the wireless interface name.
	WLAN_NAME=${LSHW_RES#*Wireless interface*logical name: }
#	WLAN_NAME=${WLAN_NAME%% *}
	WLAN_NAME=${WLAN_NAME%%$'\n'*}

	# Get the driver name
	WLAN_DRIVER=${LSHW_RES#*Wireless interface*driver=}
	WLAN_DRIVER=${WLAN_DRIVER%% *}

	# Get the IP address
	WLAN_IP=${LSHW_RES#*Wireless interface*ip=}
	WLAN_IP=${WLAN_IP%% *}

	# Sucess.
	return 0
}

# Function to get the file
call_get_file_info() {

	function call_get_resolv
	{
		echo
		echo "**************************************************************************"
		echo "resolv.conf"
		echo "**************************************************************************"

		# Does the name server file exist
		[[ -f "$RESOLV_FILE" ]] && { cat "$RESOLV_FILE"; return 0; }

		echo "$RESOLV_FILE does not exist"

		return 1;
	}

	function call_get_interfaces
	{
		echo
		echo "*************************************************************************"
		echo "interfaces"
		echo "*************************************************************************"

		[[ -f "$INTERFACES_FILE" ]] && { cat "$INTERFACES_FILE"; return 0; }

		echo "$INTERFACES_FILE does not exist"

		return 1;
	}

	function call_get_blacklisted_devices
	{
		echo
		echo "*************************************************************************"
		echo "Blacklist file"
		echo "*************************************************************************"

		[[ -f "$BLACKLIST_FILE" ]] && { cat "$BLACKLIST_FILE"; return 0; }

		echo "$BLACKLIST_FILE does not exist"

		return 1;
	}

	function call_get_modules_file
	{
		echo
		echo "**************************************************************************"
		echo "Modules file"
		echo "**************************************************************************"

		[[ -f "$MODULES_FILE" ]] && { cat "$MODULES_FILE"; return 0; }

		echo "$MODULES_FILE does not exist"

		return 1;
	}

	function call_list_all_blacklist_files
	{
		echo
		echo "**************************************************************************"
		echo "Files in folder $BLACKLIST_FOLDER"
		echo "**************************************************************************"

		for blacklist_file in  $BLACKLIST_FOLDER
		do
			echo "$blacklist_file"
		done
	}

	function call_get_nm_state_file
	{
		echo
		echo "***************************************************************************"
		echo "NetworkManager.state"
		echo "***************************************************************************"

		[[ -f "$NM_STATE_FILE" ]] && { cat "$NM_STATE_FILE"; return 0; }

		echo "$NM_STATE_FILE does not exist"

		return 1;
	}

	function call_get_nm_applet_file
	{
		echo
		echo "****************************************************************************"
		echo "nm_applet_file"
		echo "****************************************************************************" 

		[[ -f "$NM_APPLET_FILE" ]] && { cat "$NM_APPLET_FILE"; return 0; }

		echo "$NM_APPLET_FILE does not exist"

		return 1;
	}

	# Get the files.
	call_get_interfaces
	call_get_resolv
	call_get_modules_file
	call_get_blacklisted_devices
	call_list_all_blacklist_files

	if [[ "$PGREP_NM_PID" != "" ]]
	then
		# Get nm specific files.
		call_get_nm_state_file
		call_get_nm_applet_file

	elif [[ "$PGREP_WICD_PID" != "" ]]
	then
		echo
	fi
}

# Function to parse the route
call_parse_route() {

	# Get the routes. This will give us the ip address of the default gateway.
	# 0.0.0.0         xxx.xxx.xxx.xxx     0.0.0.0         UG    0      0        0 wlan0
	ROUTE_RES=$("$ROUTE" -n)

	# Did it fail ?
	[[ "$?" -eq 0  ]] || return 1

	echo
	echo "***************************************************************************"
	echo "Route info"
	echo "***************************************************************************"

	# Get the gateway ip addess. There nust be a better way to do this :(
	# A pass for each variable you need to get ?
	echo "$ROUTE_RES"
	ROUTER_PING_TARGET=$(echo "$ROUTE_RES" | awk ' $4 ~ /G/ { print $2 }')

	# Parse the route.
	[[ $ROUTER_PING_TARGET == "" ]] && { echo "Failed to parse route"; return 1; }

	# Sucess
	return 0
}

# Scan the access point.
call_scan_AP() {

	echo
	echo "******************************************************************************"
	echo "Using nm-tool"
	echo "******************************************************************************"

	# Use nm-tool
	nm-tool

	echo
	echo "******************************************************************************"
	echo "Using iwlist scan"
	echo "******************************************************************************"

	# use iwlist
	iwlist scan
}

# Function to ping a target.
# $1 ping ip address.
# $2 ping count attempts
# $3 ping retry in seconds.
# $4 Verbose (1) or quiet
# $5 The interface to ping from
call_ping_target() {

	# Sanity  check
	[[ "$1" == "" || "$2" == "" || "$3" == ""  || "$4" == ""  || "$5" == "" ]] && { echo "DEBUG: Interface value null in call_ping_target"; exit 1; }

	if (( $2 == $VERBOSE ))
	then
		echo
		echo "*********************************************************************************"
		echo "Ping test"
		echo "*********************************************************************************"
	fi

	# Ping and store the return string
	PING_RES=$("$PING" -c $2 -i $3 -I $5 $1)

	# What was the result of the ping.
	if [[ "$?" -eq 0 ]]
	then
		# success
		(( $4 == $VERBOSE )) && { echo "sucessfully pinged $1"; echo "$PING_RES"; }

		return 0
	else
		# failure
		echo "_unsucessfully_ pinged $1"

		return 1
	fi
}

# Function to perform a dns look up using nslookup
# $1 is the url to lookup
# $2 Verbose (1) or quiet (0)
#
call_nslookup() {

	# Sanity  check
	[[ "$1" == "" || "$2" == "" ]] && { echo "DEBUG: Interface value null in call_nslookup"; exit 1; }

	if (( $2 == $VERBOSE ))
	then
		echo
		echo "*************************************************************************"
		echo "nslookup test"
		echo "*************************************************************************"
	fi

	# Perform a dns lookup on the required host.
	NS_LOOKUP_RES=$("$NSLOOKUP" $1)

	if [[ "$?" -eq 0 ]]
	then
		(( $2 == $VERBOSE )) && { echo "sucessfully looked up $1"; echo "$NS_LOOKUP_RES"; }

		return 0
	else
		echo "_unsucessfully_ looked up $1"

		return 1
	fi
}

# Function to retrieve a file using wget
# $1 the url of the file to retrieve
# $2 Verbose (1)  or  Quiet (0)
#
call_wget() {

	# Sanity  check
	[[ "$1" == "" || "$2" == "" ]] && { echo "DEBUG: Interface value null in call_wget"; exit 1; }

	if (( $2 == $VERBOSE ))
	then
		echo
		echo "*******************************************************************************"
		echo "wget test"
		echo "*******************************************************************************"
	fi

	WGET_RES=$("$WGET" -q "$1")

	if [[ "$?" -eq 0 ]]
	then
		(( $2 == $VERBOSE )) && { echo "sucessfully retrieved file $1"; echo "$WGET_RES"; }

		# Delete the file.
		rm "index.html"

		return 0
	else
		echo "_unsucessfully_ retrieved file $1"

		return 1
	fi
}

# Fuunction to get a rendom ping target from the list.
call_get_random_targets() {

	# Generate a random number between 0-12
	RND=$RANDOM 
	RND=$((RND %= 13))

	# Set the ping target from the list.
	EXTERNAL_PING_TARGET=${PING_TARGETS[$RND]}

	RND=$RANDOM 
	RND=$((RND %= 10))

	# Set the the dns lookuptarget
	DNS_LOOKUP_NAME=${URL_TARGETS[$RND]}

	RND=$RANDOM 
	RND=$((RND %= 10))

	# Set up the wget target.
	WGET_URL=${URL_TARGETS[$RND]}
}

# Function to check thye connectivity to internal and external entities
# $1 Do we want continual probing ?
# $2 Interface name.
# $3 Override for verbosity. Passed into the script. CAN BE NULL.
#
call_check_connectivity() {

	# Sanity  check
	[[ "$1" == "" || "$2" == "" ]] && { echo "DEBUG: Interface value null in call_check_connectivity"; exit 1; }

	echo
	echo "********************************************************************************"
	echo "Checking connectivity"
	echo "********************************************************************************"

	# Now we want to parse the network information
	call_parse_lshw_network

	# How did that pan out ?
	[[ "$?" -eq 0 ]] || { echo "Cannot perform connectivity checking"; return 1; }	

	MODE=$VERBOSE

	# loop	while :
	while :
	do
		# Randomise the targets we will hit.
		call_get_random_targets

		# ping router. If ping fails interrogate dmesg. exit loop
		call_ping_target "$ROUTER_PING_TARGET" "$PING_TRIES" "$REPING_TIME" "$MODE" "$2"

		# Did it fail ?
		[[ "$?" == 0 ]] ||  { echo "Ping failure to router"; call_interrogate_logs; call_get_summary_network_info; return 1; }

		# ping external. If ping fails interrogate logs. exit loop
		call_ping_target "$EXTERNAL_PING_TARGET" "$PING_TRIES" "$REPING_TIME" "$MODE" "$2"

		# Did it fail ?
		[[ "$?" == 0 ]] || { echo "Ping failure to external server"; call_interrogate_logs; call_get_summary_network_info; return 1; }

		# Perform a dns lookup.
		call_nslookup "$DNS_LOOKUP_NAME" "$MODE"

		[[ "$?" == 0 ]] || { echo "nslookup failure"; call_interrogate_logs; call_get_summary_network_info; return 1; }

		# wget file. if wget fails interrogate logs. exit loop
		call_wget "$WGET_URL" "$MODE"

		# Did it fail ?
		[[ "$?" == 0 ]] || { echo "wget failure"; call_interrogate_logs; call_get_summary_network_info; return 1; }

		# Do we want continual probing ?
		[[ "$1" != "y" ]] && { return 0; }

		# sleep for a second. Hitting enter will  exit the loop.
		read -t 1 && return 0;

		# Change mode to quiet unless overridden by arguments. We don't want
		# the  log file to get too big.
		MODE=$VERBOSE_CONNECTIVITY_CHECKING
	done
}

call_interrogate_logs() {

	# Interrogate all the logs we are interested in.
	call_interrogate_log "$SYSLOG_LOG"
	call_interrogate_log "$MESSAGES_LOG"
	call_interrogate_log "$KERNEL_LOG"
}

# Function to interrogate the logs for failure information.
# Currently interrogates /var/log/messages, /var/log/syslog and /var/log/kern.log
# $1 log to interrogate.
#
call_interrogate_log() {

	# Sanity  check
	[[ "$1" == "" ]] && { echo "DEBUG: Interface value null in call_interrogate_log"; exit 1; }

	# Check the log file exists
	[[ -f "$1" ]] || { echo "Cannot find log file $1"; return 1; }

	# Log header.
	echo
	echo "******************************************************************************************"
	echo "******************************************************************************************"
	echo "Log file: $1"
	echo "******************************************************************************************"
	echo "******************************************************************************************"
	echo

	# Interrogate the log.
	cat "$1" | tail -n 30
}

# Function to get full system information from calls and files
call_get_full_system_info() {

	# Get the system information
	call_get_system_info

	# Check for failure
	[[ "$?" -ne 0 ]] && return 1

	# Get the network info
	call_get_network_info

	# Check for failure
	[[ "$?" -ne 0 ]] && return 1

	# Get the file info.
	call_get_file_info

	# Parse the route to get the default gateway
	call_parse_route

	# Check for failure
	[[ "$?" -ne 0 ]] && return 1

	# Scan for access points.
	call_scan_AP

	return "$?";
}

# Function to get the basic summary frm system calls.
call_get_summary_network_info() {

	# Get the basic system nformation
	call_get_network_info

	# Just pass on the previous return value.
	return "$?"
}

#####################################################################################################
# The meat and two veg ;)
#####################################################################################################

# clear the terminal screen.
clear

# Let the user know we are doing something
echo "Interrogating....."

# Delete any old file we many have
$(rm -rf wireless-results.txt)

# First things first. We neeed to be running with root privilages. 
call_check_root_privilages

# Initialise the script
call_initialise

# redirect stdout
call_redirect_stdout

# Open code blocks for the forums.
echo "[code]"

# Initial log entries.
echo "Version: $VERSION (Development)"
echo $($DATE_FN)
echo

# Check to see what networking services are running, get sys info and parse lshw
call_check_for_running_network_daemons
call_get_full_system_info
call_parse_lshw_network
call_interrogate_logs
# Finished

echo "Finished <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo "http://wireless.kernel.org/en/users/Drivers"
echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
# Close code blocks for the forums.
echo "[/code]"

#restore stdout
call_restore_stdout

echo "probe complete...please see 'wireless-results.txt'"

#!/bin/bash
# Script to setup my prefered environment from first boot or live environment
# 12/01/16
#
# Descripton
# Sets up initial stuff and sets up profiles according to user input.

# Global stuff

file=
verbose=0

# Main function to loop over args (do log file std/errout)

main()	{

while :; do
    case $1 in
	-c|-\?|--coding) 	# Call coding profiles
	prflcode
	echo "Setting up coding environment..."
	exit
	;;
	-t|-\?|--testing)
	prfltest
	echo "Setting up testing environment..."
	exit
	;;
	-s|-\?|--standard)
	pflstnd
	echo "Setting up testing environment..."
	exit
	;;
	-h|-\?|--help)
	help
	exit
	;;
	*)
	help
	exit
	;;
	-?*)
	help
	exit
	break
    esac
done
}

# Always check for wl driver, install and load if not found.
wless(){
    wlchk="$(lsmod | grep wl)"
    if [ -z "$wlchk" ]; then

	sudo apt-get install -y bcmwl-kernel-source 
	sudo modprobe -r ssb wl brcmfmac brcmsmac bcma
	sudo modprobe wl

    else
	echo "wl loaded..."
    fi
exit
}

prflcode(){
	wless
	sudo apt-get install -y git-all
	echo "Coding environment ready"
exit
}

prfltest(){
	wless
	sudo apt-get update && sudo apt get dist upgrade
	echo "testing environment ready"
exit
}

prflstnd(){
	wless
	sudo apt-get install -y transmission irssi
exit
}

help(){
	cat <<- EOF


	USAGE:
	./leficonfig.sh [ARG] -h | --help

	ARGS:
	-c | --coding	   setup coding env
	-t | --testing	   setup testing env
	-s | --standard	   setup standard env
	-h | --help	   this help menu

	EOF
exit
}

# Start
main


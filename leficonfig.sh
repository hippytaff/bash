#!/bin/bash
# Script to setup my prefered environment from first boot or live environment
# 12/01/16
#________________________________________________________________________________
# Descripton
# Sets up initial stuff and sets up profiles according to user input.

# Global stuff

file=
verbose=0

# Vars
chkgit="$(which git)"
chkstndi="$(which irssi)"		# Need to do an array for these, so only one test
chkstndt="$(which transmission)"	# +in pflstnd()
chkwl="$(lsmod | grep wl)"
chkenv="$(which swarmi)" 		# Check if works...bad test anyway, must be a better way
#srclist="$(sources.list)"		# change path back after tests
#srclist-backup="$~sources.list"

# Functions
# Always check for wl driver, install and load if not found. wless should go first-todo
wless(){
	echo "Checking wireless..."
    if [ -z "$chkwl" ]; then
	echo "installing and loading wl wirelss driver..."
	sudo apt-get install -y bcmwl-kernel-source
	sudo modprobe -r ssb wl brcmfmac brcmsmac bcma
	sudo modprobe wl
#Make sure wl installed here
        echo "wl loaded"
    else
	echo "wl loaded"
    fi
exit
}

prflcode(){
    if [ -z "$chkgit" ]; then
	echo "Setting up coding environment..."
	sudo apt-get install -y git-all
	echo "Good to go"
    else
	echo "Coding environment ready..."
    fi
wless
exit
}

prfltest(){
    if [ -z "$chkenv" ]; then
	echo "Setting up testing profile..."
	# Need to  update sources.list with unstable here
	sudo apt-get update && sudo apt get dist-upgrade
    else
	echo "testing environment ready..."
    fi
wless
exit
}

pflstnd(){
    if [ -z "$chkstndi" ] && [ -z "$chkstndt" ]; then # This is broken, need to research && || conditions
	echo "Setting up standard profile..."
	sudo apt-get install -y transmission irssi
	echo "Good to go"
    else
	echo "Standard environment ready..."
    fi
wless
exit
}

hlptxt(){
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

# Loop over args (todo log file std/errout)

while :; do
    case $1 in
	-c|-\?|--coding)
	prflcode
	exit
	;;
	-t|-\?|--testing)
	prfltest
	exit
	;;
	-s|-\?|--standard)
	pflstnd
	exit
	;;
	-h|-\?|--help)
	hlptxt
	exit
	;;
	*)
	hlptxt
	exit
	;;
	-?*)
	hlptxt
	exit
	break
    esac
done


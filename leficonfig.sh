#!/bin/bash
#_______________________________________________________________________________________________________
# Descripton:
# Sets up initial stuff and sets up profiles according to user input for Bodhi
# to automate my preferred set-up in a live environment or fresh install (lefi)
#
# Author:
# Hippytaff 21/01/16
#_______________________________________________________________________________________________________
# To Do:
# - Testing() needs some love. replace main with unstable in source.list mainly
# - Swarmi test isnt' gonna work. Obvs...how to test bodhi version?
# - Need arrays for standard() checks
# - Really the wireless wl install should go first before all other funcs
# - create my .bashrc, sources.list, .irssi, git...(other programme configs)
# - my moksha set-up (tzdata, keybindings...)
#_______________________________________________________________________________________________________
#Global stuff

file=
verbose=0

# Vars
chkroot="$(whoami)"
chkgit="$(which gitt)"
chkstndi="$(which irssi)"		# Need to do an array for these, so only one test
chkstndt="$(which transmission)"	# +in pflstnd()
chkwl="$(lsmod | grep wl)"
chkenv=			 		# How to check for bodhi version?
#srclist="$(sources.list)"		# change path back after tests
#srclist-backup="$~sources.list"

# Arrays
installed=("$chkstndi" "$chkstndt" "$chkgit" "$chkwl")

# Funcs
# Always check for wl driver, install and load if not found. wless should go first-todo
wless(){
	echo "Checking wireless..."
    if [ -z "${installed[3]}" ]; then
	echo "installing and loading wl wirelss driver..."
	sudo apt-get install -y bcmwl-kernel-source
	sudo modprobe -r ssb wl brcmfmac brcmsmac bcma
	sudo modprobe wl

	    if [ -z "${installed[3]}" ]; then
		echo "wl failed to install..."
	    else
        	echo "wl loaded..."
	    fi
    fi
}

prflcode(){
    if [ -z "${installed[2]}" ]; then
	sudo apt-get install -y git-all
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
	sudo apt-get update && sudo apt-get dist-upgrade
    else
	echo "testing environment ready..."
    fi
wless
exit
}

pflstnd(){
    if [ -z "${installed[0]}" || -z "${installed[1]}" ]; then # Need to research && || conditions. this will do for now.
	echo "Setting up standard profile..."
	sudo apt-get install -y transmission
	sudo apt-get install -y irssi
	    else
	echo "Good to go"
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

# Loop over args (todo log file std/errout) # To do Check for root first

# check we are root.
if [ "$chkroot" != "root" ]; then
    echo
    echo "Needs to be run as root..."
    hlptxt
    exit 1
else

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
fi

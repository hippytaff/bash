#!/bin/bash
# Basic
sudo apt-get install git autoconf automake autopoint libtool gettext

# Debug
sudo apt-get install gdb valgrind perf

# Requirements
sudo apt-get install efl elementary

# Ensure default prefix /usr/local
export PATH=/usr/local/bin:"$PATH"
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:"$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH=/usr/local/lib:"$LD_LIBRARY_PATH"

# Choose CFLAG (Replace march-native for older ARCH than build PC)
# CFLAG examples
# Optimised but debuggable   $>-02 -ffast-math -march-native -g -ggdb3
# Really debuggable	     $>-0 -g -ffast-math -march-native -ggcb3
export CFLAGS="-0.3 -ffast-math -march-native"

# Build Order
# requirements
# efl (>= 1.8.0)
# elementary (>= 1.8.0)
# terminology

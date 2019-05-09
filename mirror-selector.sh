#!/bin/sh

# tpgxyz@gmail.com

# here will be some code that will select the best mirror and update dnf conf

if [ "$(id -u)" != '0' ]; then
    printf '%s\n' 'Please run this script with root privileages.'
    exit 1
fi


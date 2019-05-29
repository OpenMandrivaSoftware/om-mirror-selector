#!/bin/sh

# tpgxyz@gmail.com 2019
# This is only a proof of concept which uses average ping
# time for each mirrors from the list and choose one with lovest time
# If anyone want to work on this you may want to make it better:
# - use geoip to get lattitude and logitude of client and mirrors ip
# - calculate distance betwwen these two IPs
# - worth to use https://en.wikipedia.org/wiki/Haversine_formula
# - grab the data from http://downloads.openmandriva.org/mm/
# - omit those mirrors which are not up to date


# List of mirrors comes from http://downloads.openmandriva.org/mm/
# (tpg) status on 2019-05-10 date
mirrors=( [1]="ftp://ftp.mirrorservice.org/sites/downloads.openmandriva.org" \
    [2]="http://www.mirrorservice.org/sites/downloads.openmandriva.org" \
    [3]="http://openmandriva.c3sl.ufpr.br" \
    [4]="ftp://distrib-coffee.ipsl.jussieu.fr/pub/linux/openmandriva" \
    [5]="http://distrib-coffee.ipsl.jussieu.fr/pub/linux/openmandriva" \
    [6]="ftp://ftp-stud.hs-esslingen.de/pub/Mirrors/openmandriva" \
    [7]="http://ftp-stud.hs-esslingen.de/pub/Mirrors/openmandriva" \
    [8]="ftp://ftp.tu-chemnitz.de/pub/linux/openmandriva" \
    [9]="http://ftp.tu-chemnitz.de/pub/linux/openmandriva" \
    [10]="ftp://ftp.nluug.nl/pub/os/Linux/distr/openmandriva" \
    [11]="http://ftp.nluug.nl/os/Linux/distr/openmandriva" \
    [12]="http://mirror.lagoon.nc/pub/openmandriva" \
    [13]="http://mirror.rise.ph/openmandriva" \
    [14]="ftp://ftp.icm.edu.pl/pub/Linux/dist/openmandriva" \
    [15]="http://ftp.icm.edu.pl/pub/Linux/dist/openmandriva" \
    [16]="ftp://ftp.vectranet.pl/mirror/openmandriva.org" \
    [17]="http://ftp.vectranet.pl/mirror/openmandriva.org" \
    [18]="ftp://ftp.pwr.wroc.pl/OpenMandriva" \
    [19]="http://ftp.pwr.wroc.pl/OpenMandriva" \
    [20]="ftp://mirror.yandex.ru/openmandriva" \
    [21]="http://mirror.yandex.ru/openmandriva" \
    [22]="http://ftp.acc.umu.se/mirror/openmandriva.org" \
    [23]="ftp://ftp.yzu.edu.tw/Linux/openmandriva" \
    [24]="http://ftp.yzu.edu.tw/Linux/openmandriva" \
    [25]="ftp://distro.ibiblio.org/openmandriva" \
    [26]="http://distro.ibiblio.org/openmandriva" )

# array with pinged mirrors
pinged_mirrors=()

if [ "$(id -u)" != '0' ]; then
    printf '%s\n' 'Please run om-mirror-selector.sh with root privileages.'
    exit 1
fi

if ! ping -c 1 example.com &> /dev/null; then
  printf '%s\n' 'Network is not available. Exiting.'
  exit 0
fi

# gathering average ping time for each mirror from array
for key in "${!mirrors[@]}"; do
    mirror="${mirrors[$key]}"
    mirror_aping="$(ping -q -c 3 $(printf '%s\n' "${mirrors[$key]}" | cut -d "/" -f3) | cut -d "/" -s -f5 | cut -d "." -s -f1)"
    pinged_mirrors+=( [${mirror_aping}]="${mirror}" )
done

# choose the mirror with lovest key (avg ping value)
best_mirror=$(printf '%s\n' "${pinged_mirrors[@]}" | head -n 1)

# update dnf repos with best mirror
if [ -e /etc/yum.repos.d/cooker-$(uname -m)-*.repo ] || [ -e /etc/yum.repos.d/openmandriva-$(uname -m)-*.repo ]; then
    sed -n -i -e "s#^baseurl=.*\/cooker#baseurl=$best_mirror\/cooker#g" -e "s#^baseurl=.*/\$releasever#baseurl=$best_mirror/\$releasever#g" /etc/yum.repos.d/{cooker,openmandriva}-*.repo
fi

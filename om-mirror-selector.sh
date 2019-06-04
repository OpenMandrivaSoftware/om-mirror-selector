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

# changes by - crazy -
mirrors=(
	http://www.mirrorservice.org/sites/downloads.openmandriva.org
	http://openmandriva.c3sl.ufpr.br
	http://distrib-coffee.ipsl.jussieu.fr/pub/linux/openmandriva
	http://ftp-stud.hs-esslingen.de/pub/Mirrors/openmandriva
	http://ftp.tu-chemnitz.de/pub/linux/openmandriva
	http://ftp.nluug.nl/pub/os/Linux/distr/openmandriva
	http://mirror.lagoon.nc/pub/openmandriva
	http://mirror.rise.ph/openmandriva
	http://ftp.icm.edu.pl/pub/Linux/dist/openmandriva
	http://ftp.vectranet.pl/mirror/openmandriva.org
	http://ftp.pwr.wroc.pl/OpenMandriva
	http://mirror.yandex.ru/openmandriva
	http://ftp.acc.umu.se/mirror/openmandriva.org
	http://ftp.yzu.edu.tw/Linux/openmandriva
	http://distro.ibiblio.org/openmandriva)

# array with pinged mirrors
declare -A pinged_mirrors

if ! ping -c 1 example.com &> /dev/null; then
  printf '%s\n' 'Network is not available. Exiting.'
  exit 0
fi

# gathering average ping time for each mirror from array
for key in "${mirrors[@]}"; do
	mirror="${key}"
	mirror_aping="$(ping -q -c 3 $(printf '%s\n' "$key" | cut -d "/" -f3) | cut -d "/" -s -f5 | cut -d "." -s -f1)"
	[[ -n $mirror_aping ]] && \
		pinged_mirrors+=( [${mirror_aping}]="${mirror}" )
done

# choose the mirror with lovest key (avg ping value)
best_mirror=$(printf '%s\n' "${pinged_mirrors[@]}" | head -n 1)

if [ "$(id -u)" != '0' ]; then
	printf '%s\n' 'You need root privileages for the next step.'
	exit 1
else
	# update dnf repos with best mirror
	if [ -e /etc/yum.repos.d/cooker-$(uname -m)-*.repo ] || [ -e /etc/yum.repos.d/openmandriva-$(uname -m)-*.repo ]; then
		sed -i -e "s#^baseurl=.*\/cooker#baseurl=$best_mirror\/cooker#g" -e "s#^baseurl=.*/\$releasever#baseurl=$best_mirror/\$releasever#g" /etc/yum.repos.d/{cooker,openmandriva}-*.repo
	fi
fi

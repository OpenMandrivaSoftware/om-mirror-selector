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
# and - bero@lindev.ch -

QUIET=false
MANUAL=false
AUTOSELECT=false
DRYRUN=false
MIRRORLIST=false
for i in "$@"; do
	case "$i" in
	-h|--help)
		cat <<EOF
Usage: $0 [-h|--help] [-q|--quiet] [-m|--manual] [-d|--dry-run]
By default, $0 returns repository configs to using
the mirror list from mirrors.openmandriva.org.

To do anything else, use the following parameters:

-a/--autoselect: Auto-select mirror with best ping time
-h/--help: Display this help text
-q/--quiet: Quiet mode - don't show progress
-m/--manual: Pick a mirror manually, don't probe ping latency
-d/--dry-run: Show what would be done instead of doing it
EOF
		exit 0
		;;
	-a|--autoselect)
		AUTOSELECT=true
		;;
	-q|--quiet)
		QUIET=true
		;;
	-m|--manual)
		MANUAL=true
		;;
	-d|--dry-run)
		DRYRUN=true
		;;
	*)
		echo "Unknown/invalid option $i" >&2
		exit 1
		;;
	esac
	shift
done

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
	http://distro.ibiblio.org/openmandriva
	http://abf-downloads.openmandriva.org)

# array with pinged mirrors
declare -A pinged_mirrors

if $MANUAL; then
	echo "Please select the mirror you want to use by typing the number next to it:"
	num=1
	for key in "${mirrors[@]}"; do
		echo "$num	$key"
		num=$((num+1))
	done
	echo
	while [ -z "$best_mirror" ]; do
		read m
		[[ "$m" =~ ^[0-9]+$ ]] && best_mirror="${mirrors[$((m-1))]}"
		[ -z "$best_mirror" ] && echo "Please enter just the number next to the mirror you'd like to use."
	done
elif $AUTOSELECT; then
	# gathering average ping time for each mirror from array
	best_time=999999999
	for key in "${mirrors[@]}"; do
		mirror="${key}"
		$QUIET || echo -n "Pinging $mirror... "
		mirror_aping="$(ping -q -c 3 $(printf '%s\n' "$key" | cut -d "/" -f3) | cut -d "/" -s -f5 | cut -d "." -s -f1)"
		if [ "$?" = "0" -a -n "$mirror_aping" ]; then
			pinged_mirrors+=( [${mirror_aping}]="${mirror}" )
			if [ -z "$best_mirror" ] || [ "$mirror_aping" -lt "$best_time" ]; then
				best_time="${mirror_aping}"
				best_mirror="${mirror}"
				$QUIET || echo "$mirror_aping ms *"
			else
				$QUIET || echo "$mirror_aping ms"
			fi
		else
			$QUIET || echo "timed out"
		fi
	done

	if [[ "${#pinged_mirrors[@]}" = "0" ]]; then
		echo "Could not reach any mirrors. Network down?"
		exit 1
	fi
else
	MIRRORLIST=true
fi

$QUIET || echo

if ! $MIRRORLIST; then
	$QUIET || echo "Selecting mirror $best_mirror"
else
	$QUIET || echo "Using mirrors.openmandriva.org"
fi

if $DRYRUN || [ "$(id -u)" != '0' ]; then
	$DRYRUN || echo 'You need root privileges for the next step.'
	echo 'Run (as root):'
	if $MIRRORLIST; then
		echo "	sed -i -e \"s|^baseurl=|# baseurl=|;s|^# mirrorlist=|mirrorlist=|\" /etc/yum.repos.d/openmandriva-*.repo"
	else
		echo "	sed -i -e \"s|^mirrorlist=|# mirrorlist=|;s|^# baseurl=|baseurl=|\" -e \"s|^baseurl=.*\/cooker|baseurl=$best_mirror/cooker|g\" -e \"s|^baseurl=.*\/rock|baseurl=$best_mirror/rock|g\" -e \"s|^baseurl=.*\/rolling|baseurl=$best_mirror/rolling|g\" -e \"s|^baseurl=.*/\$releasever|baseurl=$best_mirror/\$releasever|g\" /etc/yum.repos.d/openmandriva-*.repo"
	fi
	exit 1
else
	# update dnf repos with best mirror
	if $MIRRORLIST; then
		sed -i -e "s|^baseurl=|# baseurl=|;s|^# mirrorlist=|mirrorlist=|" /etc/yum.repos.d/openmandriva-*.repo
	else
		sed -i -e "s|^mirrorlist=|# mirrorlist=|;s|^# baseurl=|baseurl=|"  -e "s|^baseurl=.*\/cooker|baseurl=$best_mirror/cooker|g" -e "s|^baseurl=.*\/rock|baseurl=$best_mirror/rock|g" -e "s|^baseurl=.*\/rolling|baseurl=$best_mirror/rolling|g" -e "s|^baseurl=.*/\$releasever|baseurl=$best_mirror/\$releasever|g" /etc/yum.repos.d/openmandriva-*.repo
	fi
fi

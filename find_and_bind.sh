#!/bin/bash

set -e

DEVICE="wlx9cefd5fca84f"
WIFINAME="thisnetwork"
WIFIPSK="isnogood"

if ! buildah images | grep -q python-kasa ; then 
    ctr=$(buildah from debian:12)
    buildah run "$ctr" -- apt-get update -y
    buildah run "$ctr" -- apt-get install -y python3 python3-pip
    buildah run "$ctr" -- pip install --break-system-packages python-kasa
    buildah run "$ctr" -- mkdir /work
    buildah config --workingdir "/work" "$ctr"
    img=$(buildah commit "$ctr" "python-kasa")
    buildah rm "$ctr"
fi

kasa () {
    podman run -it --rm --network=host --volume "$(pwd):/work" python-kasa kasa "$@"
}

visible_ssids () {
    sudo /usr/sbin/ip link set $DEVICE up
    sudo /usr/sbin/iw $DEVICE scan \
	| grep -Po 'SSID: \K.*' \
	| sort
}

bind_new () {
    sudo /usr/sbin/iw dev $DEVICE connect -w "$1"
    sudo /sbin/dhclient $DEVICE
    ping -c 1 192.168.0.1
    kasa --host 192.168.0.1 wifi join --keytype 3 --password "$WIFIPSK" "$WIFINAME"
}

if [ $# -eq 0 ] ; then
    visible_ssids
else
    bind_new "$1"
fi

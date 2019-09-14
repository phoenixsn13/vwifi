#!/bin/bash -x

# /hosthome/vwifi/tools/start-vwifi-guest.sh

dpkg -i /hosthome/vwifi/tools/iw_4.9-0.1_amd64.deb

ip link set up wlan0
iw dev wlan0 connect mac80211_open

sleep 5s

dhclient -v wlan0

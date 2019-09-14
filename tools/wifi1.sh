#!/bin/bash -x

# /hosthome/vwifi/tools/start-vwifi-guest.sh

# >------------------------------------------------
isc_dhcp_server()
{
apt -y install isc-dhcp-server

sed -i 's/INTERFACESv4=.*/INTERFACESv4="wlan0"/g' /etc/default/isc-dhcp-server

cat >> /etc/dhcp/dhcpd.conf <<EOF

subnet 10.5.5.0 netmask 255.255.255.224 {
  range 10.5.5.26 10.5.5.30;
}
EOF

systemctl restart isc-dhcp-server
}

dnsmasq()
{
fast-dhcp wlan0

}
# ------------------------------------------------<

## fast-ip : Ok :
#fast-ip wlan0 10.5.5.1/24
## ip :
ip a a 10.5.5.1/24 dev wlan0
ip l set up wlan0

isc_dhcp_server
#dnsmasq

hostapd tests/hostapd_open.conf

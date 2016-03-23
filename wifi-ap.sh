# Copyright (c) 2016 Joseph D Poirier
# Distributable under the terms of The New BSD License
# that can be found in the LICENSE file.

#### files created and/or modified
# 1) /etc/default/isc-dhcp-server
# 2) /etc/hostapd/hostapd.conf
# 3) /etc/init.d/hostapd
# 4) /etc/network/interfaces
# 5) /etc/init.d/wifi_ap


if [ $(whoami) != 'root' ]; then
    echo "${RED}This script must be executed as root, exiting...${WHITE}"
    exit
fi

#### enable wifi if disabled
#rfkill unblock wlan

WIFIDRV=
if [ "$REVISION" == "$RPI2BxREV" ] || [ "$REVISION" == "$RPI2ByREV" ]; then
    if [ "$EW7811Un" != '' ]; then
        WIFIDRV="driver=rtl871xdrv"
    fi
fi


##############################################################
## 1) Setup DHCP server for IP address management
##############################################################
echo
echo "**** Setup DHCP server for IP address management *****"

#### should not start automatically on boot
update-rc.d isc-dhcp-server disable

### set /etc/default/isc-dhcp-server
cp -n /etc/default/isc-dhcp-server{,.bak}
cat <<EOT > /etc/default/isc-dhcp-server
NTERFACES="$wifi_interface"
EOT

### set /etc/dhcp/dhcpd.conf
cp -n /etc/dhcp/dhcpd.conf{,.bak}
cat <<EOT > /etc/dhcp/dhcpd.conf
ddns-update-style none;
default-lease-time 86400; # 24 hours
max-lease-time 172800; # 48 hours
authoritative;
log-facility local7;
subnet 192.168.10.0 netmask 255.255.255.0 {
    range 192.168.10.10 192.168.10.50;
    option broadcast-address 192.168.10.255;
    option domain-name "stratux.local";
    option domain-name-servers 4.2.2.2;
}
EOT

echo "${GREEN}...done${WHITE}"


##############################################################
## 1) Setup /etc/hostapd/hostapd.conf
##############################################################
echo
echo "${YELLOW}**** Setup /etc/hostapd/hostapd.conf *****${WHITE}"

#### should not start automatically on boot
update-rc.d hostapd disable

# what wifi interface, e.g. wlan0, wlan1..., uses the first one
wifi_interface=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
#wifi_interface=wlano

echo "${MAGENTA}...configuring $wifi_interface interface...${WHITE}"

cat <<EOT > /etc/hostapd/hostapd.conf
interface=$wifi_interface
ssid=stratux
$WIFIDRV
ieee80211n=1
hw_mode=g
channel=1
wmm_enabled=1
ignore_broadcast_ssid=0
EOT

echo "${GREEN}...done${WHITE}"


##############################################################
## 3) Setup /etc/init.d/hostapd
##############################################################
echo
echo "**** Setup /etc/init.d/hostapd *****${WHITE}"

#### edit /etc/init.d/hostapd
cp -n /etc/init.d/hostapd{,.bak}

if grep -q "DAEMON_CONF=" "/etc/init.d/hostapd"; then
    line=$(grep -n 'DAEMON_CONF=' /etc/init.d/hostapd | awk -F':' '{print $1}')
    sed "$line s/.*/DAEMON_CONF=\/etc\/hostapd\/hostapd.conf/" -i /etc/init.d/hostapd
else
    echo
    echo "${BOLD}${RED}ERROR - /etc/init.d/hostapd is missing, exiting... !!!!!!!!${WHITE}${NORMAL}"
    exit
fi

echo "${GREEN}...done${WHITE}"


##############################################################
## 4) Setup /etc/network/interfaces
##############################################################
echo
echo "${YELLOW}**** Setup /etc/network/interfaces *****${WHITE}"

cp -n /etc/network/interfaces{,.bak}

cat <<EOT > /etc/network/interfaces
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

allow-hotplug wlan0

iface wlan0 inet static
  address 192.168.10.1
  netmask 255.255.255.0
EOT

echo "${GREEN}...done${WHITE}"


#################################################
## 5) Setup /etc/init.d/wifiap
#################################################
echo
echo "${YELLOW}**** Setup /etc/init.d/wifiap *****${WHITE}"

rm -f /etc/init.d/wifiap

cat <<EOT > /etc/init.d/wifiap
#!/bin/bash

### BEGIN INIT INFO
# Provides:          wifiap
# Required-Start:    $network
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start:     2
# Default-Stop:      6
# Short-Description: Stratux Wifi Access Point
# Description:       Stratux Wifi Access Point
### END INIT INFO

function stop {
    ### stop services dhcpd and hostapd
    service isc-dhcp-server stop
    service hostapd stop
}

function start {
    stop
    sleep 3
    rfkill unblock wlan
    rfkill unblock wifi
    ### start services dhcpd and hostapd
    service hostapd start
    service isc-dhcp-server start
}

### start/stop wifi access point
case "\$1" in
    start) start ;;
    stop)  stop  ;;
esac
EOT

chmod +x /etc/init.d/wifiap

echo "${GREEN}...done${WHITE}"


#################################################
## Setup hostapd symlink
#################################################
echo
echo "${YELLOW}**** Setup hostapd symlink *****${WHITE}"

#### fixes missing symlinks error
rm -f /etc/rc2.d/S02hostapd
ln -s /etc/init.d/hostapd /etc/rc2.d/S02hostapd
#update-rc.d hostapd default

echo "${GREEN}...done${WHITE}"


#################################################
## Setup wifiap service
#################################################
echo
echo "${YELLOW}**** Setup wifiap service *****${WHITE}"

#### start service at bootup
rm -f /etc/rc2.d/S02wifiap
rm -f /etc/rc6.d/S06wifiap
ln -s /etc/init.d/wifiap /etc/rc2.d/S02wifiap
ln -s /etc/init.d/wifiap /etc/rc6.d/S06wifiap
update-rc.d wifiap enable

echo "${GREEN}...done${WHITE}"


#################################################
## Display usage message
#################################################
### display usage message
echo "${MAGENTA}
======================================
Wifi Access Point setup
You can start and stop it with:
    service wifiap start
    service wifiap stop
${WHITE}"

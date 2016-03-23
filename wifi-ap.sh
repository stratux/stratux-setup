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


##############################################################
## Edimax dongle check
##############################################################
WIFIDRV=
if [ "$REVISION" == "$RPI2BxREV" ] || [ "$REVISION" == "$RPI2ByREV" ]; then
    if [ "$EW7811Un" != '' ]; then
        WIFIDRV="driver=rtl871xdrv"
        echo "${MAGENTA}Edimax dongle found (EW7811Un), setting driver=rtl871xdrv${WHITE}"
    fi
fi


##############################################################
## 1) Setup DHCP server for IP address management
##############################################################
echo
echo "**** Setup DHCP server for IP address management *****"

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
    default-lease-time 12000;
    max-lease-time 12000;
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

# what wifi interface, e.g. wlan0, wlan1..., uses the first one
#wifi_interface=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
wifi_interface=wlan0

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
  post-up /usr/sbin/service isc-dhcp-server start
EOT

echo "${GREEN}...done${WHITE}"


#################################################
## Enable hostapd and isc-dhcp services
#################################################
echo
echo "${YELLOW}**** Enable hostapd and isc-dhcp services *****${WHITE}"

#### legacy file check
if [ -f "/etc/init.d/wifiap" ]; then
    service wifiap stop
    rm -f /etc/init.d/wifiap
    echo "${MAGENTA}legacy wifiap service stopped and file removed... *****${WHITE}"
fi

update-rc.d hostapd enable
update-rc.d isc-dhcp-server enable

echo "${GREEN}...done${WHITE}"


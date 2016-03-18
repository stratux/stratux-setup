#!/bin/bash

#### files created
# /etc/dhcp/dhcpd.conf
# /etc/hostapd/hostapd.conf
# /etc/network/interfaces
# /etc/default/isc-dhcp-server

# /etc/default/hostapd
# /etc/init.d/wifi_ap



##### make sure that this script is executed from root
if [ $(whoami) != 'root' ]; then
    echo "This script should be executed as root or with sudo: sudo $0"
    exit 0
fi

#### enable wifi if disabled
#rfkill unblock wlan

WIFIDRV=
IEEE80211N=
if [ "$EW7811Un" != '' ]; then
    WIFIDRV="driver=rtl871xdrv"
    IEEE80211N="ieee80211n=1"
fi

##############################################################
## Check if the wireless card supports Access Point mode
##############################################################
#supports_access_point=$(iw list | sed -n -e '/* AP$/p')
#if [ "$supports_access_point" = '' ]; then
#    echo "AP is not supported by the driver of the wireless card."
#    echo "This script does not work for this driver."
#    exit 0
#fi

##############################################################
##  Setup the access point
##############################################################
echo
echo "**** ... *****"
echo

#### should not start automatically on boot
update-rc.d hostapd disable

# what wifi interface, e.g. wlan0, wlan1...
wifi_interface=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')
#wifi_interface=wlano

echo
echo "**** Configuring $wifi_interface interface... *****"
echo

# TODO: check for edimax dongle
#### set /etc/hostapd/hostapd.conf
cat <<EOT > /etc/hostapd/hostapd.conf
interface=$wifi_interface
ssid=stratux
$WIFIDRV
$IEEE80211N
hw_mode=g
channel=1
wmm_enabled=1
ignore_broadcast_ssid=0
EOT

#### edit /etc/init.d/hostapd
cp -n /etc/init.d/hostapd{,.bak}


if grep -q "DAEMON_CONF=" "/etc/init.d/hostapd"; then
    line=$(grep -n 'DAEMON_CONF=' /etc/init.d/hostapd | awk -F':' '{print $1}')
    sed "$line s/.*/DAEMON_CONF=\/etc\/hostapd\/hostapd.conf/" -i /etc/init.d/hostapd
else
    echo 
    echo "!!!!!!!! Error, /etc/init.d/hostapd is missing, exiting... !!!!!!!!"
    echo
fi

##############################################################
## Set up DHCP server for IP address management
##############################################################
echo
echo "**** ... *****"
echo

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

##############################################################
## Set network interface
##############################################################
echo
echo "**** Set network interface *****"
echo

### set /etc/network/interfaces
cp -n /etc/network/interfaces{,.bak}

cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback
iface eth0 inet dhcp
allow-hotplug wlan0

iface wlan0 inet static
  address 192.168.10.1
  netmask 255.255.255.0
  #post-up /usr/sbin/stratux-wifi.sh
EOT

#################################################
## Create a startup script
#################################################

cat <<EOT > /etc/init.d/wifi_ap
#!/bin/bash
ext_interface=\$(ip route | grep default | cut -d' ' -f5)
function stop_ap {
    ### stop services dhcpd and hostapd
    service isc-dhcp-server stop
    service hostapd stop
    
    ### remove the static IP from the wifi interface
    #if grep -q 'auto $wifi_interface' /etc/network/interfaces
    #then
    #    sed -i /etc/network/interfaces -e '/auto $wifi_interface/,\$ d'
    #    sed -i /etc/network/interfaces -e '\$ d'
    #fi
    ### restart network manager to takeover wifi management
    service network-manager restart
}
function start_ap {
    stop_ap
    sleep 3
    ### see: https://bugs.launchpad.net/ubuntu/+source/wpa/+bug/1289047/comments/8
    #nmcli nm wifi off
    rfkill unblock wlan
    rfkill unblock wifi
    ### give a static IP to the wifi interface
    #ip link set dev $wifi_interface up
    #ip address add 10.10.0.1/24 dev $wifi_interface
    ### protect the static IP from network-manger restart
    #echo >> /etc/network/interfaces
    #echo 'auto $wifi_interface' >> /etc/network/interfaces
    #echo 'iface $wifi_interface' inet static >> /etc/network/interfaces
    #echo 'address 192.168.10.1' >> /etc/network/interfaces
    #echo 'netmask 255.255.255.0' >> /etc/network/interfaces
    ### start services dhcpd and hostapd
    service hostapd start
    service isc-dhcp-server start
}
### start/stop wifi access point
case "\$1" in
    start) start_ap ;;
    stop)  stop_ap  ;;
esac
EOT

chmod +x /etc/init.d/wifi_ap

### make sure that it is stopped on boot
sed -i /etc/rc.local  -e '/service wifi_ap stop/ d'
sed -i /etc/rc.local  -e '/^exit/ i service wifi_ap stop'

### display usage message
echo "
======================================
Wifi Access Point installed.
You can start and stop it with:
    service wifi_ap start
    service wifi_ap stop
"

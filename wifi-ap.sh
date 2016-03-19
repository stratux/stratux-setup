#!/bin/bash

##### files created or modified
# 1) /etc/dhcp/dhcpd.conf
# 2) /etc/init.d/hostapd
# 3) /etc/hostapd/hostapd.conf
# 4) /etc/network/interfaces
# 5) /etc/default/isc-dhcp-server
# 6) /etc/init.d/wifi_ap


if [ $(whoami) != 'root' ]; then
    echo "This script must be executed as root, exiting..."
    exit 0
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
## Check if the wireless card supports Access Point mode
##############################################################
#supports_access_point=$(iw list | sed -n -e '/* AP$/p')
#if [ "$supports_access_point" = '' ]; then
#    echo "AP is not supported by the driver of the wireless card."
#    echo "This script does not work for this driver."
#    exit 0
#fi

##############################################################
## 1) Setup /etc/dhcp/dhcpd.conf
##############################################################
echo
echo "**** Setup /etc/dhcp/dhcpd.conf *****"

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

echo "...done"

##############################################################
## 2) Setup /etc/init.d/hostapd
##############################################################
echo
echo "**** Setup /etc/init.d/hostapd *****"

#### edit /etc/init.d/hostapd
cp -n /etc/init.d/hostapd{,.bak}

if grep -q "DAEMON_CONF=" "/etc/init.d/hostapd"; then
    line=$(grep -n 'DAEMON_CONF=' /etc/init.d/hostapd | awk -F':' '{print $1}')
    sed "$line s/.*/DAEMON_CONF=\/etc\/hostapd\/hostapd.conf/" -i /etc/init.d/hostapd
else
    echo
    echo "!!!!!!!! Error, /etc/init.d/hostapd is missing, exiting... !!!!!!!!"
    exit 0
fi

echo "...done"

##############################################################
## 3) Setup /etc/hostapd/hostapd.conf
##############################################################
echo
echo "**** Setup /etc/hostapd/hostapd.conf *****"

#### should not start automatically on boot
update-rc.d hostapd disable

# what wifi interface, e.g. wlan0, wlan1..., uses the first one
wifi_interface=$(lshw -quiet -c network | sed -n -e '/Wireless interface/,+12 p' | sed -n -e '/logical name:/p' | cut -d: -f2 | sed -e 's/ //g')

echo "...configuring $wifi_interface interface..."

cat <<EOT > /etc/hostapd/hostapd.conf
interface=$wifi_interface
ssid=stratux
$WIFIDRV
ieee80211n=1
hw_mode=g
channel=1
wmm_enabled=1
macaddr_acl=0
ignore_broadcast_ssid=0
EOT

echo "...done"

##############################################################
## 4) Setup /etc/network/interfaces
##############################################################
echo
echo "**** Setup /etc/network/interfaces *****"

cp -n /etc/network/interfaces{,.bak}

cat <<EOT > /etc/network/interfaces
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

allow-hotplug wlan0

iface wlan0 inet static
  address 192.168.10.1
  netmask 255.255.255.0
EOT

echo "...done"

##############################################################
## 5) Setup /etc/default/isc-dhcp-server
##############################################################
echo
echo "**** Setup /etc/default/isc-dhcp-server *****"
echo

#### should not start automatically on boot
update-rc.d isc-dhcp-server disable

### set /etc/default/isc-dhcp-server
cp -n /etc/default/isc-dhcp-server{,.bak}
cat <<EOT > /etc/default/isc-dhcp-server
NTERFACES="$wifi_interface"
EOT

echo "...done"


#################################################
## 6) Setup /etc/init.d/wifiap
#################################################
echo
echo "**** Setup /etc/init.d/wifiap *****"

cat <<EOT > /etc/init.d/wifiap
#!/bin/bash

### BEGIN INIT INFO
# Provides:          wifiap
# Required-Start:
# Required-Stop:
# Should-Start:
# Should-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Stratux Wifi Access Point
# Description: Stratux
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

echo "...done"

#################################################
## Setup hostapd symlink
#################################################
echo
echo "**** Setup hostapd symlink *****"

#### fixes missing symlinks error
ln -s /etc/init.d/hostapd /etc/rc2.d/S02hostapd
#update-rc.d hostapd default

echo "...done"

#################################################
## Setup wifiap service
#################################################
echo
echo "**** Setup wifiap service *****"

#### start service at bootup
update-rc.d wifiap enable

echo "...done"

#################################################
## Display usage message
#################################################
### display usage message
echo "
======================================
Wifi Access Point setup
You can start and stop it with:
    service wifiap start
    service wifiap stop
"

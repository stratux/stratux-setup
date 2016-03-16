#!/bin/sh

# Assumes you're logged in as root and the folder
# is sitting in your root directory.

# to execute the script: # bash stratux-setup.sh
# autodetects RPi2 or RPi3

echo "**** Startux Setup Starting... *****"

ntpd -q -g

if ! grep -q "max_usb_current=1" "/boot/config.txt"; then
    echo "max_usb_current=1" >>/boot/config.txt
fi

if ! grep -q "dtparam=i2c1=on" "/boot/config.txt"; then
    echo "dtparam=i2c1=on" >>/boot/config.txt
fi

if ! grep -q "dtparam=i2c1_baudrate=400000" "/boot/config.txt"; then
    echo "dtparam=i2c1_baudrate=400000" >>/boot/config.txt
fi

if ! grep -q "dtparam=i2c_arm_baudrate=400000" "/boot/config.txt"; then
    echo "dtparam=i2c_arm_baudrate=400000" >>/boot/config.txt
fi

#echo "arm_freq=900" >>boot/config.txt
#echo "sdram_freq=450" >>boot/config.txt
#echo "core_freq=450" >>boot/config.txt

#disable serial console
sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"

apt-get install -y git
git config --global http.sslVerify false

apt-get install -y wget
apt-get install -y screen
apt-get install -y isc-dhcp-server
apt-get install -y tcpdump
apt-get install -y cmake libusb-1.0-0.dev build-essential
apt-get install -y mercurial
apt-get install -y autoconf fftw3 fftw3-dev
apt-get install -y libtool
apt-get install -y automake
# install hostapd for side effects
apt-get install -y hostapd

REVISION="$(cat /proc/cpuinfo | grep Revision | cut -d ':' -f 2 | xargs)"
if [ "$REVISION" == "a01041" ] || [ "$REVISION" == "a21041" ]; then
    # RPi2 specific hostapd binary
    echo "**** RPi2 specific hostapd installation *****"
    rm -f /usr/sbin/hostapd

    echo "hostapd edimax source"
    # http://www.edimax.com/images/Image/Driver_Utility/Wireless/NIC/EW-7811Un/EW-7811Un_Linux_driver_v1.0.0.5.zip
    # Realtek downloads page http://152.104.125.41/downloads/downloadsView.aspx?Langid=1&PNid=21&PFid=48&Level=5&Conn=4&ProdID=27...
    unzip wpa_supplicant_hostapd.zip
    cd wpa_supplicant_hostapd/hostapd
    make

    if [ ! -f ./hostapd ]; then
        echo "ERROR - hostapd doesn't exist, exiting..."
        exit 0
    fi

    # install the binary
    mv ./hostapd /usr/sbin/hostapd
    chmod +x /usr/sbin/hostapd

    cd ../../
    rm -rf wpa_supplicant_hostapd/
    cp -f ./files/hostapd.conf /etc/hostapd/hostapd.conf

    if ! grep -q "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" "/etc/modprobe.d/8192cu.conf"; then
        echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" >>/etc/modprobe.d/8192cu.conf
    fi
elif [ "$REVISION" == "a01041" ]; then
    echo "**** RPi3 specific hostapd installation *****"
    cp -f ./files/hostapdRPi3.conf /etc/hostapd/hostapd.conf
else
    echo "**** Inable to identify the board using /proc/cpuinfo, exiting *****"
    exit 0
fi

mkdir -p /etc/ssh/authorized_keys
cp -f ./files/root /etc/ssh/authorized_keys/root
chown root.root /etc/ssh/authorized_keys/root
chmod 644 /etc/ssh/authorized_keys/root

cp -f ./files/dhcpd.conf /etc/dhcp/dhcpd.conf

cp -f ./files/interfaces /etc/network/interfaces
cp -f ./files/isc-dhcp-server /etc/default/isc-dhcp-server
cp -f ./files/sshd_config /etc/ssh/sshd_config
cp -f ./files/wifi_watch.sh /usr/sbin/wifi_watch.sh
chmod +x /usr/sbin/wifi_watch.sh
cp -f ./files/rc.local /etc/rc.local
rm -f /usr/share/dbus-1/system-services/fi.epitest.hostap.WPASupplicant.service


if grep -q "DAEMON_CONF=" "/etc/default/hostapd"; then
    line=$(grep -n 'DAEMON_CONF=' etc/default/hostapd | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi
echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >/etc/default/hostapd

if ! grep -q "blacklist dvb_usb_rtl28xxu" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist dvb_usb_rtl28xxu >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist e4000" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist e4000 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist rtl2832" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist rtl2832 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "# prevent power down of wireless when idle" "/etc/modprobe.d/8192cu.conf"; then
    echo "# prevent power down of wireless when idle" >>/etc/modprobe.d/8192cu.conf
fi

# Go environment setup
# if any of the following environment variables are set in .bashrc delete them
if grep -q "export GOROOT_BOOTSTRAP=" "/root/.bashrc"; then
    line=$(grep -n 'GOROOT_BOOTSTRAP=' /root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi

if grep -q "export GOROOT=" "/root/.bashrc"; then
    line=$(grep -n 'GOROOT=' root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi

if grep -q "export GOPATH=" "/root/.bashrc"; then
    line=$(grep -n 'GOPATH=' /root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi

if grep -q "export PATH=" "/root/.bashrc"; then
    line=$(grep -n 'PATH=' /root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi

# only add new paths
XPATH=
if [[ ! "$PATH" =~ "/root/go/bin" ]]; then
    XPATH+=:/root/go/bin
fi

if [[ ! "$PATH" =~ "/root/gopath/bin" ]]; then
    XPATH+=:/root/gopath/bin
fi

echo export GOROOT_BOOTSTRAP=/root/gobootstrap >>/root/.bashrc
echo export GOPATH=/root/gopath >>/root/.bashrc
echo export GOROOT=/root/go >>/root/.bashrc
echo export PATH=\$PATH$XPATH >>/root/.bashrc


source /root/.bashrc

# Go compiler installation
cd /root

rm -rf go/
rm -rf gobootstrap/

# get and set up the Go bootstrap compiler
wget https://storage.googleapis.com/golang/go1.6.linux-armv6l.tar.gz
tar -zxvf go1.6.linux-armv6l.tar.gz
mv go gobootstrap
rm -f go1.6.linux-armv6l.tar.gz

rm -rf /root/gopath
mkdir -p /root/gopath

# get and build the latest go compiler
# As far as RPi-2/3, is there any real advantage
# to compiling from source?
wget https://storage.googleapis.com/golang/go1.6.src.tar.gz
tar -zxvf go1.6.src.tar.gz
rm go1.6.src*

# make.bash skips the post build tests, all.bash doesn't
cd go/src
bash ./make.bash

cd /root

rm -rf gobootstrap/



echo "*** STRATUX COMPILE/PACKAGE INSTALL ***"
echo " - RTL-SDR tools"


rm -rf librtlsdr
git clone https://github.com/jpoirier/librtlsdr
cd librtlsdr
mkdir build
cd build
cmake ../
make
make install
ldconfig


echo "*** Stratux ***"

cd /root

rm -rf stratux
git clone https://github.com/cyoung/stratux --recursive
cd stratux
# checkout the latest release
git checkout v0.8r1
make all
make install

#i2c
if ! grep -q "i2c-bcm2708" "/etc/modules"; then
    echo "i2c-bcm2708" >>/etc/modules
fi

if ! grep -q "i2c-dev" "/etc/modules"; then
    echo "i2c-dev" >>/etc/modules
fi


##### sysctl tweaks
if grep -q "net.core.rmem_max" "/etc/sysctl.conf"; then
    line=$(grep -n 'net.core.rmem_max' /etc/sysctl.conf | awk -F':' '{print $1}')d
    sed -i $line /etc/sysctl.conf
fi

if grep -q "net.core.rmem_default" "/etc/sysctl.conf"; then
    line=$(grep -n 'net.core.rmem_default' /etc/sysctl.conf | awk -F':' '{print $1}')d
    sed -i $line /etc/sysctl.conf
fi

if grep -q "net.core.wmem_max" "/etc/sysctl.conf"; then
    line=$(grep -n 'net.core.wmem_max' /etc/sysctl.conf | awk -F':' '{print $1}')d
    sed -i $line /etc/sysctl.conf
fi

if grep -q "net.core.wmem_default" "/etc/sysctl.conf"; then
    line=$(grep -n 'net.core.wmem_default' /etc/sysctl.conf | awk -F':' '{print $1}')d
    sed -i $line /etc/sysctl.conf
fi
echo "net.core.rmem_max = 167772160" >>/etc/sysctl.conf
echo "net.core.rmem_default = 167772160" >>/etc/sysctl.conf
echo "net.core.wmem_max = 167772160" >>/etc/sysctl.conf
echo "net.core.wmem_default = 167772160" >>/etc/sysctl.conf


##### kalibrate-rl
cd /root

rm -rf kalibrate-rtl
git clone https://github.com/steve-m/kalibrate-rtl
cd kalibrate-rtl
./bootstrap
./configure
make
make install

##### disable serial console
if [ -f /etc/inittab ]; then
    sed -i /etc/inittab -e "s|^.*:.*:respawn:.*ttyAMA0|#&|"
fi


##### Set the keyboard layout to US.
if [ -f /etc/default/keyboard ]; then
    sed -i /etc/default/keyboard -e "/^XKBLAYOUT/s/\".*\"/\"us\"/"
fi

# allow starting services
if [ -f /usr/sbin/policy-rc.d ]; then
    rm /usr/sbin/policy-rc.d
fi


#wifi startup
update-rc.d hostapd enable
update-rc.d isc-dhcp-server enable
#disable ntpd autostart
if which ntp >/dev/null; then
    update-rc.d ntp disable
fi
update-rc.d stratux enable

echo "**** END STRATUX SETUP *****"
echo "**** Don't forget to reboot! *****"

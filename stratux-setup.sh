#!/bin/sh

if [ $(whoami) != 'root' ]; then
    echo "This script must be executed as root, exiting..."
    exit 0
fi

BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
LIME_YELLOW=$(tput setaf 190)
POWDER_BLUE=$(tput setaf 153)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)
BRIGHT=$(tput bold)
NORMAL=$(tput sgr0)
BLINK=$(tput blink)
REVERSE=$(tput smso)
UNDERLINE=$(tput smul)

SCRIPTDIR="`pwd`"

cd /root

#set -e

#outfile=setuplog
#rm -f $outfile

#exec > >(cat >> $outfile)
#exec 2> >(cat >> $outfile)

#### stdout and stderr to log file
#exec > >(tee -a $outfile >&1)
#exec 2> >(tee -a $outfile >&2)

#### execute the script: bash stratux-setup.sh

#### Revision numbers found via cat /proc/cpuinfo
RPI2BxREV=a01041
RPI2ByREV=a21041
RPI3BxREV=a02082
ODROIDC2=020b

EW7811Un=$(lsusb | grep EW-7811Un)

echo
echo "************************************"
echo "**** Stratux Setup Starting... *****"
echo "************************************"
echo

ntpd -q -g

##############################################################
##  Dependencies
##############################################################
echo
echo "**** Installing dependencies... *****"

apt-get install -y git
git config --global http.sslVerify false

apt-get install -y iw
apt-get install -y lshw
apt-get install -y wget
apt-get install -y screen
#apt-get install -y isc-dhcp-server
apt-get install -y tcpdump
apt-get install -y cmake
apt-get install -y libusb-1.0-0.dev
apt-get install -y build-essential
apt-get install -y mercurial
apt-get install -y autoconf
apt-get install -y fftw3
apt-get install -y fftw3-dev
apt-get install -y libtool
apt-get install -y automake
apt-get install -y hostapd
apt-get install -y rfkill
apt-get install -y dnsmasq

echo "...done"

##############################################################
##  Hardware checkout
##############################################################
echo
echo "**** Hardware checkout... *****"

REVISION="$(cat /proc/cpuinfo | grep Revision | cut -d ':' -f 2 | xargs)"
if [ "$REVISION" == "$RPI2BxREV" ] || [ "$REVISION" == "$RPI2ByREV" ]  || [ "$REVISION" == "$RPI3BxREV" ]; then
    echo
    echo "**** Raspberry Pi detected... *****"

    source $SCRIPTDIR/rpi.sh
elif [ "$REVISION" == "$ODROIDC2" ]; then
    echo
    echo "**** Odroid-C2 detected... *****"

    source $SCRIPTDIR/odroid.sh
else
    echo
    echo "**** Unable to identify the board using /proc/cpuinfo, exiting *****"

    exit 0
fi

echo "...done"

##############################################################
##  SSH steup and config
##############################################################
echo
echo "**** SSH setup and config... *****"

if [ ! -d "$DIRECTORY" ]; then
    mkdir -p /etc/ssh/authorized_keys
fi

cp -n /etc/ssh/authorized_keys/root{,.bak}
cp -f $SCRIPTDIR/files/root /etc/ssh/authorized_keys/root
chown root.root /etc/ssh/authorized_keys/root
chmod 644 /etc/ssh/authorized_keys/root

cp -n /etc/ssh/sshd_config{,.bak}
cp -f $SCRIPTDIR/files/sshd_config /etc/ssh/sshd_config
rm -f /usr/share/dbus-1/system-services/fi.epitest.hostap.WPASupplicant.service

echo "...done"

##############################################################
##  Hardware blacklisting
##############################################################
echo
echo "**** Hardware blacklisting... *****"

if ! grep -q "blacklist dvb_usb_rtl28xxu" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist dvb_usb_rtl28xxu >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist e4000" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist e4000 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist rtl2832" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist rtl2832 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

echo "...done"

##############################################################
##  Go environment setup
##############################################################
echo
echo "**** Go environment setup... *****"

# if any of the following environment variables are set in .bashrc delete them
if grep -q "export GOROOT_BOOTSTRAP=" "/root/.bashrc"; then
    line=$(grep -n 'GOROOT_BOOTSTRAP=' /root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /root/.bashrc
fi

if grep -q "export GOROOT=" "/root/.bashrc"; then
    line=$(grep -n 'GOROOT=' /root/.bashrc | awk -F':' '{print $1}')d
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
echo 'export PATH=$PATH$XPATH' >>/root/.bashrc

source /root/.bashrc

echo "...done"

##############################################################
##  Go bootstrap compiler installtion
##############################################################
echo
echo "**** Go bootstrap compiler installtion... *****"

cd /root

rm -rf go/
rm -rf gobootstrap/

wget https://storage.googleapis.com/golang/go1.6.linux-armv6l.tar.gz
tar -zxvf go1.6.linux-armv6l.tar.gz
if [ ! -d /root/go ]; then
    echo "Error - go folder doesn't exist, exiting..."
    exit 0
fi

rm -f go1.6.linux-armv6l.tar.gz
rm -rf /root/gopath
mkdir -p /root/gopath

echo "...done"

##############################################################
##  Go host compiler build
##############################################################
echo
echo "**** Go host compiler build... *****"

cd /root

if [ "$REVISION" == "$RPI2BxREV" ] || [ "$REVISION" == "$RPI2ByREV" ]; then
    #### For RPi-2/3, is there any disadvantage to using the armv6l compiler?
    #### to compiling from source?
    echo "...not necessary, done"
else
    mv go gobootstrap
    wget https://storage.googleapis.com/golang/go1.6.src.tar.gz
    tar -zxvf go1.6.src.tar.gz
    rm go1.6.src*

    make.bash to skip the post build tests
    cd go/src
    bash ./make.bash

    cd /root
    rm -rf gobootstrap/

    echo "...done"
fi

##############################################################
##  RTL-SDR tools build
##############################################################
echo
echo "**** RTL-SDR library build... *****"

cd /root

rm -rf librtlsdr
git clone https://github.com/jpoirier/librtlsdr
cd librtlsdr
mkdir build
cd build
cmake ../
make
make install
ldconfig

echo "...done"

##############################################################
##  Stratux build and installation
##############################################################
echo
echo "**** Stratux build and installation... *****"

cd /root

rm -rf stratux
git clone https://github.com/cyoung/stratux --recursive
cd stratux
# checkout the latest release
git checkout v0.8r1
make all
make install

echo "...done"

##############################################################
##  Kalibrate build and installation
##############################################################
echo
echo "**** Kalibrate build and installation... *****"

cd /root

rm -rf kalibrate-rtl
git clone https://github.com/steve-m/kalibrate-rtl
cd kalibrate-rtl
./bootstrap
./configure
make
make install

echo "...done"

##############################################################
##  System tweaks
##############################################################
echo
echo "**** System tweaks... *****"

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

echo "...done"

##############################################################
##  WiFi Access Point setup
##############################################################
echo
echo "**** WiFi Access Point setup... *****"

source /$SCRIPTDIR/wifi-ap.sh

#### disable ntpd autostart
if which ntp >/dev/null; then
    update-rc.d ntp disable
fi

####
update-rc.d stratux enable

echo
echo "**** Setup complete, don't forget to reboot! *****"
echo

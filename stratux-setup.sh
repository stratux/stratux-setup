#!/bin/sh

if [ $(whoami) != 'root' ]; then
    echo "This script must be executed as root, exiting..."
    exit 0
fi

SCRIPTDIR=$PWD

cd /root

#set -e 

#outfile=setuplog
#rm -f $outfile

#exec > >(cat >> $outfile)
#exec 2> >(cat >> $outfile)

#### stdout and stderr to log file
#exec > >(tee -a $outfile >&1)
#exec 2> >(tee -a $outfile >&2)

# execute the script: bash stratux-setup.sh

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
echo

apt-get install -y git
git config --global http.sslVerify false

apt-get install -y iw
apt-get install -y lshw
apt-get install -y wget
apt-get install -y screen
apt-get install -y isc-dhcp-server
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

##############################################################
##  Platform and hardware specific items
##############################################################
REVISION="$(cat /proc/cpuinfo | grep Revision | cut -d ':' -f 2 | xargs)"
if [ "$REVISION" == "$RPI2BxREV" ] || [ "$REVISION" == "$RPI2ByREV" ]  || [ "$REVISION" == "$RPI3BxREV" ]; then
    echo
    echo "**** Raspberry Pi detected... *****"
    echo
    source $SCRIPTDIR/rpi.sh
elif [ "$REVISION" == "ODROIDC2" ]; then
    source $SCRIPTDIR/odroid.sh
else
    echo "**** Unable to identify the board using /proc/cpuinfo, exiting *****"
    exit 0
fi

##############################################################
##  SSH steup and config
##############################################################
echo
echo "**** SSH setup and config... *****"
echo

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


##############################################################
##  Hardware blacklisting
##############################################################
echo
echo "**** Hardware blacklisting... *****"
echo

if ! grep -q "blacklist dvb_usb_rtl28xxu" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist dvb_usb_rtl28xxu >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist e4000" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist e4000 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "blacklist rtl2832" "/etc/modprobe.d/rtl-sdr-blacklist.conf"; then
    echo blacklist rtl2832 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
fi

if ! grep -q "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" "/etc/modprobe.d/8192cu.conf"; then
    echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" >>/etc/modprobe.d/8192cu.conf
fi

##############################################################
##  Go environment setup
##############################################################
echo
echo "**** Go environment setup... *****"
echo

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
echo export PATH=\$PATH$XPATH >>/root/.bashrc

source /root/.bashrc

##############################################################
##  Go bootstrap compiler installtion
##############################################################
echo
echo "**** Go bootstrap compiler installtion... *****"
echo

cd /root

rm -rf go/
rm -rf gobootstrap/

wget https://storage.googleapis.com/golang/go1.6.linux-armv6l.tar.gz
tar -zxvf go1.6.linux-armv6l.tar.gz
mv go gobootstrap
rm -f go1.6.linux-armv6l.tar.gz

rm -rf /root/gopath
mkdir -p /root/gopath

##############################################################
##  Go host compiler build
##############################################################
echo
echo "**** Go host compiler build... *****"
echo

cd /root
mv gobootstrap go
#### For RPi-2/3, is there any disadvantage to using the armv6l compiler?
#### to compiling from source?
#wget https://storage.googleapis.com/golang/go1.6.src.tar.gz
#tar -zxvf go1.6.src.tar.gz
#rm go1.6.src*

# make.bash to skip the post build tests
#cd go/src
#bash ./make.bash

#cd /root
#rm -rf gobootstrap/

##############################################################
##  RTL-SDR tools build
##############################################################
echo
echo "**** RTL-SDR library build... *****"
echo

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

##############################################################
##  Stratux build and installation
##############################################################
echo
echo "**** Stratux build and installation... *****"
echo

cd /root

rm -rf stratux
git clone https://github.com/cyoung/stratux --recursive
cd stratux
# checkout the latest release
git checkout v0.8r1
make all
make install


##############################################################
##  Kalibrate build and installation build
##############################################################
echo
echo "**** Kalibrate build and installation build... *****"
echo

cd /root

rm -rf kalibrate-rtl
git clone https://github.com/steve-m/kalibrate-rtl
cd kalibrate-rtl
./bootstrap
./configure
make
make install

##############################################################
##  System tweaks
##############################################################
echo
echo "**** System tweaks... *****"
echo

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

##############################################################
##  WiFi Access Point setup
##############################################################
echo
echo "**** WiFi Access Point setup... *****"
echo

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

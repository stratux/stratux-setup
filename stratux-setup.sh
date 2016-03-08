#!/bin/sh

# Assumes you're logged in as root and the folder
# is sitting in your root directory.

# to execute the script $ bash stratux-setup.sh

echo "**** STRATUX SETUP *****"

ntpd -q -g

#mkdir boot
#echo "max_usb_current=1" >>boot/config.txt
#echo "dtparam=i2c1=on" >>boot/config.txt
#echo "dtparam=i2c1_baudrate=400000" >>boot/config.txt
#echo "dtparam=i2c_arm_baudrate=400000" >>boot/config.txt
#echo "arm_freq=900" >>boot/config.txt
#echo "sdram_freq=450" >>boot/config.txt
#echo "core_freq=450" >>boot/config.txt

#disable serial console
#sed -i boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"

apt-get install -y git
git config --global http.sslVerify false

apt-get install -y wget
apt-get install -y screen
apt-get install -y isc-dhcp-server
apt-get install -y tcpdump
apt-get install -y cmake libusb-1.0-0.dev build-essential
apt-get install -y mercurial
apt-get install -y autoconf libfftw3 libfftw3-dev
apt-get install -y libtool

# RPi2 specific hostapd binary
echo "**** RPi2 specific hostapd installation *****"
mv /usr/sbin/hostapd /usr/sbin/hostapd.orig
rm -rf hostapd-*
wget http://www.juergenkeil.de/download/hostapd-2.2.rtl871xdrv.gz
gunzip hostapd-2.2.rtl871xdrv.gz
mv hostapd-2.2.rtl871xdrv /usr/sbin/hostapd
chmod +x /usr/sbin/hostapd
# ln -s /usr/sbin/hostapd-2.2.rtl871xdrv /usr/sbin/hostapd

#cd ./wpa_supplicant_hostapd/hostapd
#make
#if [ ! -f ./hostapd ]
#then
#    echo "ERROR - hostapd doesn't exist, exiting..."
#    exit 0
#fi
#mv ./hostapd /usr/sbin/hostapd
#chmod +x /usr/sbin/hostapd
#make clean

cd ../../

mkdir -p /etc/ssh/authorized_keys
cp -f ./root /etc/ssh/authorized_keys/root
chown root.root /etc/ssh/authorized_keys/root
chmod 644 /etc/ssh/authorized_keys/root

cp -f ./dhcpd.conf /etc/dhcp/dhcpd.conf
cp -f ./hostapd.conf /etc/hostapd/hostapd.conf
cp -f ./interfaces /etc/network/interfaces
cp -f ./isc-dhcp-server /etc/default/isc-dhcp-server
cp -f ./sshd_config /etc/ssh/sshd_config
cp -f ./wifi_watch.sh /usr/sbin/wifi_watch.sh
chmod +x /usr/sbin/wifi_watch.sh
cp -f ./rc.local /etc/rc.local
rm -f /usr/share/dbus-1/system-services/fi.epitest.hostap.WPASupplicant.service

echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >/etc/default/hostapd

echo blacklist dvb_usb_rtl28xxu >>/etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist e4000 >>/etc/modprobe.d/rtl-sdr-blacklist.conf
echo blacklist rtl2832 >>/etc/modprobe.d/rtl-sdr-blacklist.conf

echo "# prevent power down of wireless when idle" >>/etc/modprobe.d/8192cu.conf
echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" >>/etc/modprobe.d/8192cu.conf


cd /root

rm -rf go
rm -rf go1.5.3

#get and set up the Go bootstrap compiler
wget http://dave.cheney.net/paste/go1.5.3.linux-arm.tar.gz
tar -zxvf go1.5.3.linux-arm.tar.gz
rm -f go1.5.3*
mv go go1.5.3


mkdir -p /root/gopath


# if the environment variables is set in .bashrc delete it

if grep -q "export GOROOT_BOOTSTRAP=" "/home/root/.bashrc";
 then
    line=$(grep -n 'GOROOT_BOOTSTRAP=' /home/root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /home/root/.bashrc
fi

if grep -q "export GOROOT=" "/home/root/.bashrc";
 then
    line=$(grep -n 'GOROOT=' /home/root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /home/root/.bashrc
fi

if grep -q "export GOPATH=" "/home/root/.bashrc";
 then
    line=$(grep -n 'GOPATH=' /home/root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /home/root/.bashrc
fi

if grep -q "export PATH=" "/home/root/.bashrc";
 then
    line=$(grep -n 'PATH=' /home/root/.bashrc | awk -F':' '{print $1}')d
    sed -i $line /home/root/.bashrc
fi


# only add new paths
XPATH=
if [[ ! "$PATH" =~ "/root/go/bin" ]]; then
    XPATH+=:/root/go/bin
fi

if [[ ! "$PATH" =~ "/root/gopath/bin" ]]; then
    XPATH+=:/root/gopath/bin
fi

echo export GOPATH=/root/gopath >>/root/.bashrc
echo export GOROOT=/root/go >>/root/.bashrc
echo export GOROOT_BOOTSTRAP=/root/go1.5.3 >>/root/.bashrc
echo export PATH=$PATH$XPATH >>/root/.bashrc


source /root/.bashrc

# get and build the latest go compiler
wget https://storage.googleapis.com/golang/go1.6.src.tar.gz
tar -zxvf go1.6.src.tar.gz
rm go1.6.src.tar.gz

# make.bash skips the post build tests, all.bash doesn't
cd go/src
bash ./make.bash


echo "*** STRATUX COMPILE/PACKAGE INSTALL ***"
echo " - RTL-SDR tools"

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


echo "*** Stratux ***"

cd /root

rm -rf stratux
git clone https://github.com/cyoung/stratux --recursive
cd stratux
make all
make install

#i2c
echo "i2c-bcm2708" >>/etc/modules
echo "i2c-dev" >>/etc/modules


##### sysctl tweaks
echo "net.core.rmem_max = 167772160" >>/etc/sysctl.conf
echo "net.core.rmem_default = 167772160" >>/etc/sysctl.conf
echo "net.core.wmem_max = 167772160" >>/etc/sysctl.conf
echo "net.core.wmem_default = 167772160" >>/etc/sysctl.conf


##### kalibrate-rl
cd /root

git clone https://github.com/steve-m/kalibrate-rtl
cd kalibrate-rtl
./bootstrap
./configure
make
make install

##### disable serial console
sed -i /etc/inittab -e "s|^.*:.*:respawn:.*ttyAMA0|#&|"

##### Set the keyboard layout to US.
sed -i /etc/default/keyboard -e "/^XKBLAYOUT/s/\".*\"/\"us\"/"


#wifi startup
update-rc.d hostapd enable
update-rc.d isc-dhcp-server enable
#disable ntpd autostart
update-rc.d ntp disable
update-rc.d stratux enable

echo "**** END STRATUX SETUP *****"
echo "**** Don't forget to reboot! *****"

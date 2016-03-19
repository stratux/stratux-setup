
echo
echo "************************************"
echo "****** Raspberry Pi setup... *******"
echo "************************************"
echo

##############################################################
##  Boot config settings
##############################################################
echo
echo "**** Boot config settings... *****"
echo

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

echo "...done"

##############################################################
##  Disable serial console
##############################################################
echo
echo "**** Disable serial console... *****"
echo

sed -i /boot/cmdline.txt -e "s/console=ttyAMA0,[0-9]\+ //"

echo "...done"

##############################################################
##  Edimax wifi dongle check
##############################################################
echo
echo "**** Edimax wifi dongle check... *****"
echo

if [ "$EW7811Un" != '' ]; then
    echo "edimax wifi dongle found, copying the hostapd binary... *****"

    cd $SCRIPTDIR
    rm -f /usr/sbin/hostapd

    #echo "hostapd edimax source"
    #### http://www.edimax.com/images/Image/Driver_Utility/Wireless/NIC/EW-7811Un/EW-7811Un_Linux_driver_v1.0.0.5.zip
    #### Realtek downloads page http://152.104.125.41/downloads/downloadsView.aspx?Langid=1&PNid=21&PFid=48&Level=5&Conn=4&ProdID=27...
    #rm -rf wpa_supplicant_hostapd/
    #unzip wpa_supplicant_hostapd.zip
    #cd wpa_supplicant_hostapd/hostapd
    #make

    gunzip -k hostapd.gz
    if [ ! -f ./hostapd ]; then
        echo "ERROR - hostapd doesn't exist, exiting..."
        exit 0
    fi

    # install the binary
    mv ./hostapd /usr/sbin/hostapd
    chmod +x /usr/sbin/hostapd

    #cd $SCRIPTDIR
    #rm -rf wpa_supplicant_hostapd/

    if ! grep -q "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" "/etc/modprobe.d/8192cu.conf"; then
        echo "options 8192cu rtw_power_mgnt=0 rtw_enusbss=0" >>/etc/modprobe.d/8192cu.conf
    fi
else
    echo "edimax wifi dongle not found, nothing to do... *****"
fi

echo "done..."

##############################################################
##  I2C setup
##############################################################
echo
echo "**** I2C setup... *****"
echo

if ! grep -q "i2c-bcm2708" "/etc/modules"; then
    echo "i2c-bcm2708" >>/etc/modules
fi

if ! grep -q "i2c-dev" "/etc/modules"; then
    echo "i2c-dev" >>/etc/modules
fi

echo "done..."

##############################################################
##  Sysctl tweaks
##############################################################
echo
echo "**** Sysctl tweaks... *****"
echo

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

echo "...done"

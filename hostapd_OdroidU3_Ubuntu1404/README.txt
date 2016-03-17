If hostapd does not work on your Odroid U3 running Ubuntu 14.04, please try backing up the existing hostapd and hostapd_cli:

cd /usr/sbin
mkdir hostapd_bak
mv hostapd hostapd_bak
mv hostapd_cli hostapd_bak

And then copy in the hostapd and hostapd_cli file from this zip to the /usr/sbin directory.

Tested on RPi2, Raspbian Jessie Lite (requires image resize)

Commands

    login via command line, user: pi  pwd: raspberry

    # sudo su -
    # raspi-config
        select option 1 - expand filesystem

    # apt-get update
    # apt-get upgrade
        reboot and log back in as root

    # cd /root
    # apt-get install git
    # git config --global http.sslVerify false

    # git clone https://github.com/jpoirier/stratux-setup
    # cd stratux-setup

    # bash stratux-setup.sh 2.2|src|[default]
        *the default hostapd is used when no option is passed

Note, versions prior to ~March 9th, 2016, polluted PATH and
.bashrc with redundant info and you should manually edit to
clean-up said items.

- requires an ethernet connection
- if you use a lite image (e.g. Raspbian Jessie Lite)
  you'll need to increase its size
- for RPi3, there are two parts in the stratux-setup.sh
  file that will (most likely) need to change, the
  RPi2 specific hostapd installation, see below.

TODO - get it working on RPi3 and ODROID-C2

Concerning RPi3, reddit.com/user/ldc2010 commented here
https://www.reddit.com/r/stratux/comments/490qpk/is_raspberry_pi_3_compatible_with_stratux_image/
pointing to the following link for driver changes
https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/

RPi3 uses nl80211 WiFi driver

Note, most of the contents of stratux-setup.sh was pulled from
https://github.com/cyoung/stratux/blob/master/image/spindle/wheezy-stage4


Minimal xserver installation https://www.raspberrypi.org/forums/viewtopic.php?p=890408#p890408

Tested on RPi2, Raspbian Jessie and *Jessie Lite (requires image resize)

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

    # bash stratux-setup.sh [3]
    Pass 3 as an option if running on an RPi3 to bypass
    installing the edimax wifi specific hostapd binary


- requires an ethernet connection

Note, older versions polluted files with redundant info (e.g.
.bashrc and other files that have values echoed to them) when
stratux-setup was run multiple times.

TODO - get it working on RPi3 and ODROID-C2 and others?

Concerning RPi3, reddit.com/user/ldc2010 commented here
https://www.reddit.com/r/stratux/comments/490qpk/is_raspberry_pi_3_compatible_with_stratux_image/
pointing to the following link for driver changes
https://frillip.com/using-your-raspberry-pi-3-as-a-wifi-access-point-with-hostapd/

RPi3 uses nl80211 WiFi driver

Note, most of the contents of stratux-setup.sh was pulled from
https://github.com/cyoung/stratux/blob/master/image/spindle/wheezy-stage4


Minimal xserver installation https://www.raspberrypi.org/forums/viewtopic.php?p=890408#p890408

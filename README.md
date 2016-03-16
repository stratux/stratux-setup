Tested on RPi2, Raspbian Jessie and *Jessie Lite (requires image resize)

This script checkouts the revision that corresponds to the latest stratux
release, if want to run tip comment out, e.g. git checkout v0.8r1

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

    # bash stratux-setup.sh
        autodetects RPi2 or RPi3


- requires an ethernet connection

Note, older versions polluted files with redundant info (e.g.
.bashrc and other files that have values echoed to them) when
stratux-setup was run multiple times.

TODO - get it working on RPi3 and ODROID-C2 and others?

RPi3 uses nl80211 WiFi driver

Note, most of the contents of stratux-setup.sh was pulled from
https://github.com/cyoung/stratux/blob/master/image/spindle/wheezy-stage4

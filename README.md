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
        will detect RPi2, RPi3, and Odroid-C2 currently
        
    reboot

Requirements

    - apt-get 
    - ethernet connection

Add a hardware hook for your board:

    - create a bash file containing you hard specific setting
      and add a detection mechanism to the "Platform and hardware
      specific items" section in the stratux-setup.sh file.
      See the rpi.sh file for an example.
      
WiFi config settings hook:
    - TODO

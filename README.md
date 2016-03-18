An alternative method for installing Stratux on your board's stock Linux OS.

Why use a setup script rather than an image to install stratux?

For most, the stratux image is what you should use for your installation. 
The setup script does offer the ability to use stratux on almost any Linux
distro that'll run on your preferred board with a fairly straightforward 
way to add support for additional Linux boards beyond an RPi2 or RPi3. 

Tested on RPi2, Raspbian Jessie, Jessie Lite (requires image resize),
and Odroid-C2 Ubuntu64-16.04lts-mate.

Note, this script checkouts the revision that corresponds to the latest
stratux release, if you want to run the bleeding edge stratux code comment out
the "git checkout" line in the stratux-setup.sh file:  git checkout v0.8r1

Note, you can go back to any previous stratux revision by opening a command line
prompt in /root/stratux, issuing a "git checkout" command and running "make all"
then "make install." E.g.

    # cd /root/stratux
    # service stratux stop
    
    # git checkout v0.8r1
        or
    # git checkout master
    
    # make all
    # make install
    
    Although you could restart stratux via "service stratux start" it's
    advisable to reboot.

Commands

    login via command line (RPi - user: pi  pwd: raspberry

    # sudo su -
    
    # raspi-config
        select option 1 - expand filesystem
        this is an RPi only command

    # apt-get update
    # apt-get upgrade
        reboot and log back in as root

    # cd /root
    # apt-get install git
    # git config --global http.sslVerify false

    # git clone https://github.com/jpoirier/stratux-setup
    # cd stratux-setup

    # bash stratux-setup.sh
        will currently detect RPi2, RPi3, and Odroid-C2
        
    # reboot

Requirements

    - Linux OS
    - apt-get
    - ethernet connection

Add a hardware hook for your board:

    - create a bash file containing your hardware specific settings
      (eg see the rpi.sh file) then add a detection mechanism to the 
      "Platform and hardware specific items" section in the 
      stratux-setup.sh file (eg see the "Revision numbers").

WiFi config settings hook:

    - for the majority of systems the current wifi setup should
      work but for those cases where it doesn't it should be a
      simple matter to add a modified version of the wifi script
      and use the same detection mechanism to import the necessary
      file. 

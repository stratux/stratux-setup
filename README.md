First cut stratux setup script to allow the use of stock/default OS image 

Commands

    login via command line, user: pi  pwd: raspberry
    # sudo su -
    # cd /root
    
    # apt-get update
    # apt-get upgrade

    # apt-get install git
    # git config --global http.sslVerify false

    # git clone https://github.com/jpoirier/stratux-setup
    # cd stratux-setup

    # bash stratux-setup.sh

- quickly tested on RPi2, Raspbian Jessie Lite
- requires an ethernet connection
- if you use a lite image (e.g. Raspbian Jessie Lite) 
  you'll need to increase its size
- for RPi3, there are two parts in the stratux-setup.sh
  file that will (most likely) need to change, the
  "RPi2 specific hostapd installation" part and the Go
  compiler. 

TODO - get it working on RPi3 and ODROID-C2 


Note, most of the contents of stratux-setup.sh was pulled from
https://github.com/cyoung/stratux/blob/master/image/spindle/wheezy-stage4

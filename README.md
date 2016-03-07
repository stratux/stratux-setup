
Commands

    login via command line, user: pi  pwd: raspberry
    sudo su -
    cd /root
    apt-get install git
    git config --global http.sslVerify false

    git clone https://github.com/jpoirier/stratux-setup
    cd stratux-setup

    screen
    bash stratux-setup.sh

- requires an ethernet connection
- if you use a *lite image (e.g. Raspbian Jessie Lite) 
  you'll need to increase its size

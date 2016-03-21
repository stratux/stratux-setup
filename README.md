An alternative method for installing Stratux on your board's Linux OS.

Both 1090ES and 978UAT SDR dongles have been tested on RPi2, Raspbian
Jessie and Jessie Lite (requires image resize), as well as, Odroid-C2
Ubuntu64-16.04lts-mate. Both the RPI2 and Odroid boards worked with an
Edimax EW-7811Un and Odroid Module 0 (Ralink RT5370) Wifi
USB adapter, no extra configuration required. But virtually any natively
supported Wifi USB adapter should work.


Pre-installations commands:

    # cd /root/stratux
    # service stratux stop

    # git checkout v0.8r1
        or
    # git checkout master

    # make all
    # make install

    Although you could restart stratux via "service stratux stop/start" it's
    advisable to reboot.


Commands to run the setup script:

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


Q: What version of stratux does the setup script download and install?

A: The setup script checks out and builds the latest version of the stratux
code from the official stratux repository.

Note, you can check out and install any version of the stratux source code by
opening a command line prompt in /root/stratux, issuing a "git checkout some-rev"
command, where some-rev can be either a sha1 hash or tag, and running
"make all" then "make install" and reboot.


Q: Why use a setup script to manually install stratux as opposed to using the official image?

A: For most, the official stratux image is what you should use.
With that said, the setup script does offer the ability to use stratux on
many other boards that run Linux with a fairly straightforward approach to
adding support for Linux boards beyond RPi2s or RPi3s.


Q: How does it work?

A: The stratux-setup script downloads, builds, and installs source code from the
main (official) stratux repository and makes small modification to a network file;
the setup script sets up a different dhcp server than what the image uses.
Specifically, the setup script installs dnsmasq, as opposed to isc-dhcp-server.


Q: Does the stratux setup script differ from the installation provided by the official image?

A: Yes, as stated in the previous answer, the setup script uses dnsmasq for
its dhcp server whereas the official image uses isc-dhcp-server. The switch does
require a change to the network.go file so stratux knows where the dhcp lease file is
located and how to parse said file. For that reason, the setup script includes
a modified version of the file in the root of the script folder and copies it
to stratux/main prior to compiling the stratux middleware.


Q: Are there any parts that don't work if I use an unsupported board, eg an Odroid-C2?

A: Yes. Those parts that connect via GPIO are unsupported at the moment,
therefore, you're restricted to just traffic and/or weather information,
depending on which SDR dongle you're using.


Notes:

    - the setup script uses its own wifi service, and although there's
      no need to manually start and stop the it, if for some reason
      you do need to, e.g. debugging, use the following commands:

          service wifiap stop
          service wifiap start

Requirements:

    - Linux compatible board
    - Linux OS
    - apt-get
    - ethernet connection
    - wifi
    - keyboard
    - a little command line fu


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


A 35,750 foot view of stratux:

    +------------------------------+
    | Board (eg RPi2, Odroid-C2)  |
    | +--------------------------+ |
    | |         Linux            | |
    | +--------------------------+ |
    | ||   Stratux Middleware   || |
    | ||                        || |    +-------------+   \/
    | || +---+Process 1090 data || |<---+1090ES Dongle|----   (optional)
    | || |                      || |    +-------------+
    | || |                      || |    +-------------+   \/
    | || +---+Process 978 data  || |<---+978UAT Dongle|----   (optional)
    | || |                      || |    +-------------+
    | || |                      || |              +---+   \/
    | || +---+Process GPS info  || |<-------------+GPS|----   (optional)
    | || |                      || |              +---+
    | || |                      || |             +----+   \/
    | || +---+Process AHRS info || |<------------+AHRS|----   (optional)
    | || |                      || |             +----+
    | || +---+Build message/s   || |
    | || |                      || |           +------+   \/
    | || +--->Send messages---> || |<----------> Wifi |----
    | ||                        || |           +------+
    | |--------------------------| |
    | +--------------------------+ |
    +------------------------------+

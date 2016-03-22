An alternative method for installing Stratux on your board's Linux OS.

Both 1090ES and 978UAT SDR dongles have been tested on RPi2, Raspbian
Jessie and Jessie Lite (requires image resize), as well as, Odroid-C2
Ubuntu64-16.04lts-mate. Both the RPI2 and Odroid boards worked with an
Edimax EW-7811Un and Odroid Module 0 (Ralink RT5370) Wifi
USB adapter, no extra configuration required. But virtually any natively
supported Wifi USB adapter should work.


Commands to run the setup script:

    login via command line

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
code from the official stratux git repository.

Note, you can check out and install any version of the stratux source code by
opening a command line prompt in /root/stratux, issuing a "git checkout some-rev"
command, where some-rev can be either a sha1 hash or tag, and running
"make all" then "make install" and reboot. To see what revisions are available for
checkout issue a "git branch" command.


Q: Why use a setup script to manually install stratux as opposed to using the official image?

A: For most, the official stratux image is what you should use.
With that said, the setup script does offer the ability to use stratux on
many other boards that run Linux with a fairly straightforward approach to
adding support for Linux boards beyond RPi2 and RPi3.


Q: How does it work?

A: The stratux-setup script downloads, builds, and installs source code from the
official stratux git repository and it sets up the necessary dhcp server using
the same isc-dhcp-server binary as on the stratux image.


Q: Does the stratux setup script differ from the installation provided by the official image?

A: No. The stratux-setup script makes no modifications and for all intents and purposes
the stratux-setup installation is identical to that of the official image.


Q: Are there any parts that don't work if I use an unsupported board, eg an Odroid-C2?

A: Yes. Those parts that connect via GPIO are unsupported at this time,
therefore, you're restricted to those USB devices you'd use with the official image,
e.g. SDR and/or GPS USB devices.


Notes:

    - the setup script uses its own wifi service, and although there
      is no need to manually start it post setup, if for some reason
      you do need to start and/or stop it, e.g. for debugging, use
      the following commands:

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

    +--------------------------------+
    | Board (eg RPi2, Odroid-C2)     |
    | +----------------------------+ |
    | |         Linux              | |
    | +----------------------------+ |
    | ||   Stratux Middleware     || |
    | ||                          || |    +-------------+   \/
    | || +---+ Process 1090 data  || |<---+1090ES Dongle|----   (optional)
    | || |                        || |    +-------------+
    | || |                        || |    +-------------+   \/
    | || +---+ Process 978 data   || |<---+978UAT Dongle|----   (optional)
    | || |                        || |    +-------------+
    | || |                        || |              +---+   \/
    | || +---+ Process GPS info   || |<-------------+GPS|----   (optional)
    | || |                        || |              +---+
    | || |                        || |             +----+   \/
    | || +---+ Process AHRS info  || |<------------+AHRS|----   (optional)
    | || |                        || |             +----+
    | || Build outgoing message/s || |
    | || |                        || |           +------+   \/
    | || +---> Send messages ---> || |<----------> Wifi |----
    | ||                          || |           +------+
    | |----------------------------| |
    | +----------------------------+ |
    +--------------------------------+

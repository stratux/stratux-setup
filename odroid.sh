# Copyright (c) 2016 Joseph D Poirier
# Distributable under the terms of The New BSD License
# that can be found in the LICENSE file.

echo
echo "************************************"
echo "********* Odroid setup... **********"
echo "************************************"
echo


##############################################################
## Remove the firewall
##############################################################
echo
echo "${YELLOW}Remove the firewall...${WHITE}"

apt-get remove -y ufw

echo "${GREEN}...done${WHITE}"


##############################################################
## Set folder permissions
##############################################################
echo
echo "${YELLOW}Set folder permissions...${WHITE}"

chmod g+w /usr/bin/
chmod g+w /usr/sbin/
chmod g+w /etc/init.d/
chmod 777 /etc/rc2.d/
chmod 777 /etc/rc6.d/

echo "${GREEN}...done${WHITE}"

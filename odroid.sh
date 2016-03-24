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

echo
echo "************************************"
echo "********* Odroid setup... **********"
echo "************************************"
echo


##############################################################
## Uninstalling the firewall
##############################################################
echo
echo "${YELLOW}**** Disable firewall *****${WHITE}"

apt-get remove -y ufw

echo "${GREEN}...done${WHITE}"

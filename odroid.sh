echo
echo "************************************"
echo "********* Odroid setup... **********"
echo "************************************"
echo


##############################################################
## Disable firewall
##############################################################
echo
echo "${YELLOW}**** Disable firewall *****${WHITE}"

#### disable the firewall
#### TODO: check distro
ufw disable

echo "${GREEN}...done${WHITE}"

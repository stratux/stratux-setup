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
if which ufw >/dev/null; then
    ufw disable
fi

echo "${GREEN}...done${WHITE}"

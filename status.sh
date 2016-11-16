service inetutils-inetd status
inetd_code=$?
service tftpd-hpa status
tftpd_code=$?
service isc-dhcp-server status
dhcp_code=$?
service nginx status
nginx_code=$?
service squid-deb-proxy status
squid_code=$?
service ntp status
ntp_code=$?

if [ $inetd_code -eq 0 ]
then
	echo "inetd is online"
else
	echo "inetd is offline"
fi

if [ $tftpd_code -eq 0 ]
then
	echo "TFTP is online"
else
	echo "TFTP is offline"
fi

if [ $dhcp_code -eq 0 ]
then
	echo "DHCP is online"
else
	echo "DHCP is offline"
fi

if [ $nginx_code -eq 0 ]
then
	echo "nginX is online"
else
	echo "nginX is offline"
fi

if [ $squid_code -eq 0 ]
then
	echo "squid is online"
else
	echo "squid is offline"
fi

if [ $ntp_code -eq 0 ]
then
	echo "ntp is online"
else
	echo "ntp is offline"
fi

# reset all packages and settings
apt purge inetutils-inetd
apt purge tftpd-hpa 
apt purge isc-dhcp-server
apt purge nginx
apt purge squid-deb-proxy
apt purge ntp

backup_replace() {
	ext=".bkp"
	mv $2 $2$ext
	cp $1 $2
}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#===================
#    DCHP Server    
#===================
# isc-dhcp-server
#   dynamic host config protocol (for assigning IP addresses to computers in the network
apt install isc-dhcp-server

# Configure DHCP server
# Interact with server via `sudo service isc-dhcp-server {status|start|stop|restart}`
backup_replace DIR/dhcpd.conf /etc/dhcp/dhcpd.conf

backup_replace DIR/isc-dhcp-server /etc/default/isc-dhcp-server

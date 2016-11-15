backup_replace() {
	ext=".bkp"
	mv $2 $2$ext
	cp $1 $2
}
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

verbose=1
NC='\033[0m'
GREEN='\033[0;32m'
verbose_print() {
	if [ $verbose -eq 1 ]
	then
		echo -e "$GREEN$1$NC"
	fi
}

# reset all packages and settings
apt purge inetutils-inetd
apt purge tftpd-hpa 
apt purge isc-dhcp-server
apt purge nginx
apt purge squid-deb-proxy
apt purge ntp

#===================
#    DCHP Server    
#===================
# isc-dhcp-server
#   dynamic host config protocol (for assigning IP addresses to computers in the network
# Interact with server via `sudo service isc-dhcp-server {status|start|stop|restart}`
apt install isc-dhcp-server
verbose_print "DHCP: server installed"

# Configure DHCP server
backup_replace "$DIR/dhcpd.conf" /etc/dhcp/dhcpd.conf
verbose_print "DHCP: DHCP subnets configured"

# Limit DHCP response service to the eth0 (do not serve over wifi)
backup_replace "$DIR/isc-dhcp-server" /etc/default/isc-dhcp-server
verbose_print "DHCP: network interfaces configured"

# Configure network interfaces
# claim static IP 192.168.2.1 for the eth0 connection
backup_replace "$DIR/interfaces" /etc/network/interfaces
verbose_print "DHCP: static IP address configured"


#===================
#    TFTP Server    
#===================
# tftpd-hpa
#   trivial file transfer protocol server
# Interact with `service tftpd-hpa {status|start|stop|restart|force-reload}`
apt install tftpd-hpa
verbose_print "TFTP: server installed"

# Configure TFTP server.
backup_replace "$DIR/tftpd-hpa" /etc/default/tftpd-hpa
verbose_print "TFTP: configured"


#===================
#    inetd  Server    
#===================
#inetd service used to start tftpd on boot
apt install inetutils-inetd
verbose_print "INETD: installed"

#configure inetd to start tftpd
backup_replace "$DIR/inetd.conf" /etc/inetd.conf
verbose_print "INETD: configured"


#=====================
#    Netboot Image
#=====================
# Install the netboot image for use
if [ -f "/var/lib/tftpboot/netboot.tar.gz" ]
then
	verbose_print "boot image: already exists. Not re-acquiring"
else
	mkdir /var/lib/tftpboot
	cd /var/lib/tftpboot/
	wget archive.ubuntu.com/ubuntu/dists/xenial-updates/main/installer-amd64/current/images/netboot/netboot.tar.gz
	tar vxzf netboot.tar.gz
	verbose_print "boot image: Acquired"
fi

# configure PXE boot image selection and source
chmod +w /var/lib/tftpboot/pxelinux.cfg/default
backup_replace "$DIR/pxe.default" /var/lib/tftpboot/pxelinux.cfg/default
verbose_print "boot image: configured"


#=================
#    Webserver
#=================
# install nginx to run the server
apt install nginx
verbose_print "NGINX: installed"

# configure nginx to use /var/www [/html] as its service directory
# do an inplace edit of "/etc/.../default", replacing (s;) "/usr/share/nginx/www" with "/var/www"
sed -i 's;/usr/share/nginx/www;/var/www;' /etc/nginx/sites-available/default
mkdir -p /var/www
cd var
chown www-data:www-data www
cd www
verbose_print "NGINX: configured"

# need to put the preseed.cfg file in /var/www/html/ubuntu-16.04-preseed.cfg
cd html
cp "$DIR/ubuntu-16.04-preseed.cfg" /var/www/html/ubuntu-16.04-preseed.cfg
verbose_print "NGINX: preseed installed"


#===================
#    Other Stuff
#===================
apt install squid-deb-proxy
verbose_print "Other: squid-deb-proxy installed"
apt install ntp
verbose_print "Other: ntp installed"


#=========================
#    Reboot Everything
#=========================
# restart service to apply configuration
/etc/init.d/tftpd-hpa restart
# alt: 
# service tftpd-hpa restart
service nginx restart
/etc/init.d/isc-dhcp-server restart
/etc/init.d/squid-deb-proxy restart
/etc/init.d/ntp restart

verbose_print "Script complete"





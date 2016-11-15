# inetutils-inetd
# 	inetd is a daemon that listens on various TCP & UDP ports and spawns programs
apt install inetutils-inetd
# tftpd-hpa
#   trivial file transfer protocol (TFTP).  Servers boot images over the network for PXE
#   server edition.
apt install tftpd-hpa 
# isc-dhcp-server
#   dynamic host config protocol (for assigning IP addresses to computers in the network
apt install isc-dhcp-server



# Configure TFTP server
#   server will serve files located in TFTP_DIRECTORY
#   this command fails (even with sudo) with:
#       -bash: /etc/default/tftpd-hpa.conf: Permission denied
#   interact with `service tftpd-hpa {status|start|stop|restart|force-reload}`
cat <<EOF>>/etc/default/tftpd-hpa
# /etc/default/tftpd-hpa
RUN_DAEMON="yes"
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="[::]:69"
TFTP_OPTIONS="--secure"
EOF



# Configure DHCP server
#   this command fails with:
#       -bash: /etc/dhcp/dhcpd.conf: Permission denied
#   interact with `sudo service isc-dhcp-server {status|start|stop|restart}`
sudo cat <<EOF>>/etc/dhcp/dhcpd.conf
# security feature
ddns-update-style none;
# authoritative indicates that the DHCP server should send DHCPNAK messages to misconfigured clients
authoritative;
# 1 day
default-lease-time 86400;
# 1 week
max-lease-time 604800;

allow booting;
allow bootp;

subnet 192.168.2.0 netmask 255.255.255.0 {
    option routers 192.168.2.1;
    range 192.168.2.100 192.168.2.200;
    filename "pxelinux.0";
}
EOF


# The DHCP server should only operate on the wired connection
#   See running interfaces via ifconfig?
cat <<EOF>>/etc/default/isc-dhcp-server
INTERFACES="eth0"
EOF


# configure network interfaces
#   claim static IP 192.168.2.1 for the eth0 connection
cat <<EOF>>/etc/network/interfaces
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.2.1
    netmask 255.255.255.0
EOF



# mkdirp -p /mnt
# cd  /mnt
# cp -fr install/netboot/* /var/lib/tftpboot/

# Download and unpack the netboot boot image for PXE
mkdir /var/lib/tftpboot
cd /var/lib/tftpboot/
wget archive.ubuntu.com/ubuntu/dists/xenial-updates/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar vxzf netboot.tar.gz



# configure PXE boot image selection and source
chmod +w /var/lib/tftpboot/pxelinux.cfg/default
cat <<EOF>>/var/lib/tftpboot/pxelinux.cfg/default
default linux
label linux
    kernel ubuntu-installer/amd64/linux
    append http_proxy="http://192.168.2.1:8000" auto=true preseed/url=http://192.168.2.1/ubuntu-16.04-preseed.cfg vga=normal initrd=ubuntu-installer/amd64/initrd.gz
ramdisk_size=16432 root=/dev/rd/0 rw  --
EOF



# Configure inetd to start up the tftpd-hpa service
cat <<EOF>>/etc/inetd.conf
tftp dgram udp wait root /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /var/lib/tftpboot
EOF


/etc/init.d/tftpd-hpa restart
# Haven't passed this point yet

apt install nginx
# do an inplace edit of "/etc/.../default", replacing (s;) "/usr/share/nginx/www" with "/var/www"
sed -i 's;/usr/share/nginx/www;/var/www;' /etc/nginx/sites-available/default
mkdir -p /var/www
cd var
chown www-data:www-data www
cd www

#cp -fr /mnt/* .
mkdir -p install/netboot
cp -fr /var/lib/tftpboot/* ./install/netboot
# need to put the preseed.cfg file in /var/www/html/ubuntu-16.04-preseed.cfg
# ???


service nginx restart
/etc/init.d/isc-dhcp-server start

apt-get install squid-deb-proxy
/etc/init.d/squid-deb-proxy start

apt install ntp
/etc/init.d/ntp restart








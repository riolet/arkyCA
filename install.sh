apt install inetutils-inetd
apt install tftpd-hpa 
apt install dhcp3-server

cat <<EOF>>/etc/default/tftpd-hpa
# /etc/default/tftpd-hpa
RUN_DAEMON="yes"
TFTP_USERNAME="tftp"
TFTP_DIRECTORY="/var/lib/tftpboot"
TFTP_ADDRESS="[::]:69"
TFTP_OPTIONS="--secure"
EOF

cat <<EOF>>/etc/dhcp/dhcpd.conf
allow booting;
allow bootp;

subnet 192.168.2.0 netmask 255.255.255.0 {
	option routers 192.168.2.1;
        range 192.168.2.100 192.168.2.200;
        filename "pxelinux.0";
}
EOF

mkdirp -p /mnt
cd  /mnt
cp -fr install/netboot/* /var/lib/tftpboot/

chmod +w /var/lib/tftpboot/pxelinux.cfg/default
cat <<EOF>>/var/lib/tftpboot/pxelinux.cfg/default
default linux
label linux
        kernel ubuntu-installer/amd64/linux
        append http_proxy="http://192.168.2.1:8000" auto=true preseed/url=http://192.168.2.1/ubuntu-16.04-preseed.cfg vga=normal initrd=ubuntu-installer/amd64/initrd.gz
ramdisk_size=16432 root=/dev/rd/0 rw  --
EOF

cat <<EOF>>/etc/inetd.conf
tftp    dgram   udp    wait    root    /usr/sbin/in.tftpd /usr/sbin/in.tftpd -s /var/lib/tftpboot
EOF

/etc/init.d/tftpd-hpa restart
apt install nginx
sed -i 's;/usr/share/nginx/www;/var/www;' /etc/nginx/sites-available/default
mkdir -p /var/www
cd var
chown www-data:www-data www
cd www
cp -fr /mnt/* .
service nginx restart
/etc/init.d/isc-dhcp-server start

apt-get install squid-deb-proxy
/etc/init.d/squid-deb-proxy start

apt install ntp
/etc/init.d/ntp restart








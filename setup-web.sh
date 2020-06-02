#!/bin/bash

#Update kernal
yum update -y
yum upgrade -y
#Install required packages
yum install wget nano mod_ssl -y

#Install webmin / Virtualmin + LAMP
wget http://software.virtualmin.com/gpl/scripts/install.sh
chmod +x install.sh
./install --hostname borrecloudservice.com --force

#update php to version 7.3
yum install epel-release -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum install yum-utils -y
yum-config-manager --enable remi-php73
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-pear -y

#Enable apache
systemctl enable httpd
systemctl start httpd

#update firewall
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=10000/tcp
firewall-cmd --reload

#install bind
yum install bind bind-utils -y
systemctl enable named
systemctl start named

#create certifate
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/borrecloudservice.key -out /etc/ssl/certs/borrecloudservice.crt -subj "/C=DK/ST=Ringsted/L=Ringsted/O=Borre Cloud Service/OU=IT Department/CN=borrecloudservice.dk"

#update ssl information
cp ~/ZBCLinux/ssl.conf /etc/httpd/conf.d/
chcon system_u:object_r:httpd_config_t:s0 /etc/httpd/conf.d/ssl.conf

#Install Wordpress
wget http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
rsync -avP ~/wordpress/ /var/www/html/
mkdir /var/www/html/wp-content/uploads
cp ~/ZBCLinux/wp-config.php /var/www/html/
chcon unconfined_u:object_r:httpd_sys_content_t:s0 /var/www/html/wp-config.php
chown -R apache:apache /var/www/html/*

#Statisk IP konfigureres
sed 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'IPADDR=192.168.1.2' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'GATEWAY=192.168.1.1' >> /etc/sysconfig/network-scripts/ifcfg-ens192

#Mail server installeres (Squirl mail eller Postgre)


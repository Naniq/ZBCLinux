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

#Update mariaDB to version 10.2
cat > /etc/yum.repos.d/MariaDB.repo <<"EOF"
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

sleep 1
yum install MariaDB-server MariaDB-client -y
# Start and enable mariadb
systemctl start mariadb
systemctl enable mariadb

#Run mysql_secure_installation
mysql_secure_installation <<"EOF"

n
y
n
y
y
EOF

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

#install webmin
#cat > /etc/yum.repos.d/webmin.repo <<"EOF"
#[Webmin]
#name=Webmin Distribution Neutral
##baseurl=http://download.webmin.com/download/yum
#mirrorlist=http://download.webmin.com/download/yum/mirrorlist
#enabled=1
#EOF

#wget http://www.webmin.com/jcameron-key.asc

#rpm --import jcameron-key.asc
#yum install webmin -y

#create certifate
mkdir /etc/ssl/private
chmod 700 /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/borrecloudservice.key -out /etc/ssl/certs/borrecloudservice.crt -subj "/C=DK/ST=Ringsted/L=Ringsted/O=Borre Cloud Service/OU=IT Department/CN=borrecloudservice.dk"

#update ssl information
mv /ZBCLinux/ssl.conf /etc/httpd/conf.d/

#Install Wordpress

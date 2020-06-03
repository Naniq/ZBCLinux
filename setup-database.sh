#!/bin/bash

#Set hostname
hostnamectl set-hostname database.borrecloudservice.dk
#Update kernal
yum update -y
yum upgrade -y
#Install required packages
yum install wget -y

#Innstall mariaDB to version 10.2
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

#Create wordpress database + user
cp ~/ZBCLinux/.my.cnf ~/
mysql -u root <<"EOF"

CREATE DATABASE wordpress;
CREATE USER admin@10.100.32.175 IDENTIFIED BY 'Kode1234!';
GRANT ALL ON wordpress.* TO admin@10.100.32.175 IDENTIFIED BY 'Kode1234!';
FLUSH PRIVILEGES;
QUIT;
EOF
#Change bind ip
sed -i 's/#bind-address/bind-address/g' /etc/my.cnf.d/server.cnf

systemctl restart mariadb

#update firewall
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=3306/udp
firewall-cmd --reload

#Statisk IP konfigureres
sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'IPADDR=10.100.32.242' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'GATEWAY=10.100.32.1' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
#!/bin/bash

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

#Create wordpress database
#Create user in database admin:Kode1234!

#update firewall
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --permanent --add-port=3306/udp
firewall-cmd --reload

#Statisk IP konfigureres
sed 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'IPADDR=192.168.1.3' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'GATEWAY=192.168.1.1' >> /etc/sysconfig/network-scripts/ifcfg-ens192
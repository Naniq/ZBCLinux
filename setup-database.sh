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

#Create hidden credential files for mysql (Will allow user to login without using passsword mysql -u root)
cp ~/ZBCLinux/.my.cnf ~/

#Create wordpress database + user
mysql -u root <<"EOF"

CREATE DATABASE wordpress_borrecloudservice_dk;
CREATE USER admin@192.168.1.2 IDENTIFIED BY 'Kode1234!';
CREATE USER admin@192.168.1.5 IDENTIFIED BY 'Kode1234!';
CREATE USER admin@192.168.1.6 IDENTIFIED BY 'Kode1234!';
GRANT ALL ON wordpress_borrecloudservice_dk.* TO admin@192.168.1.2 IDENTIFIED BY 'Kode1234!';
GRANT ALL ON wordpress_borrecloudservice_dk.* TO admin@192.168.1.5 IDENTIFIED BY 'Kode1234!';
FLUSH PRIVILEGES;
QUIT;
EOF
mysql -u root <<"EOF"
CREATE DATABASE wordpress_extraborrecloudservice_dk;
GRANT ALL ON wordpress_extraborrecloudservice_dk.* TO admin@192.168.1.2 IDENTIFIED BY 'Kode1234!';
GRANT ALL ON wordpress_extraborrecloudservice_dk.* TO admin@192.168.1.6 IDENTIFIED BY 'Kode1234!';
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
sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-ens192
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'IPADDR=192.168.1.3' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-ens192
echo 'GATEWAY=192.168.1.1' >> /etc/sysconfig/network-scripts/ifcfg-ens192
/etc/sysconfig/network-scripts/ifup-eth ens192

systemctl restart network
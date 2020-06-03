#!/bin/bash


#Update kernal
yum update -y
yum upgrade -y
#Install required packages
yum install wget nano mod_ssl -y

#Install webmin / Virtualmin + LAMP
wget http://software.virtualmin.com/gpl/scripts/install.sh
chmod +x install.sh
./install --hostname borrecloudservice.dk --force

#update php to version 7.3
yum install epel-release -y
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum install yum-utils -y
yum-config-manager --enable remi-php73
yum install php php-mcrypt php-cli php-gd php-curl php-mysql php-ldap php-zip php-fileinfo php-pear -y

#install bind
yum install bind bind-utils -y
systemctl enable named
systemctl start named

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
sed -i 's/dhcp/static/g' /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'IPADDR=10.100.32.175' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'NETMASK=255.255.255.0' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo 'GATEWAY=10.100.32.1' >> /etc/sysconfig/network-scripts/ifcfg-enp0s3

#Setup postfix
echo '10.100.32.175 mail.borrecloudservice.dk borrecloudservice.dk' >> /etc/hosts
sed -i 's/#myhostname = host.domain.tld/myhostname = mail.borrecloudservice.dk/g' /etc/postfix/main.cf
sed -i 's/#mydomain = domain.tld/mydomain = borrecloudservice.dk/g' /etc/postfix/main.cf
sed -i 's/#myorigin = $mydomain/myorigin = $mydomain/g' /etc/postfix/main.cf
sed -i 's/#inet_interfaces = all/inet_interfaces = all/g' /etc/postfix/main.cf
sed -i 's/inet_interfaces = localhost/#inet_interfaces = localhost/g' /etc/postfix/main.cf
sed -i 's/mydestination = $myhostname, localhost.$mydomain, localhost/mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain/g' /etc/postfix/main.cf
sed -i 's/#mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/mynetworks = 10.100.32.0\/24, 127.0.0.0\/8/g' /etc/postfix/main.cf
sed -i 's/#home_mailbox = Maildir/home_mailbox = Maildir/g' /etc/postfix/main.cf

systemctl enable postfix
systemctl start postfix

#Create email users
useradd email-user-1; echo Kode1234! | passwd email-user-1 --stdin
useradd email-user-2; echo Kode1234! | passwd email-user-2 --stdin
useradd email-user-3; echo Kode1234! | passwd email-user-3 --stdin
useradd email-user-4; echo Kode1234! | passwd email-user-4 --stdin
useradd email-user-5; echo Kode1234! | passwd email-user-5 --stdin

#Install dovecat for Pop, imap and lmtp protcols
yum install dovecot -y
sed -i 's/#protocols/protocols/g' /etc/dovecot/dovecot.conf
sed -i 's/#   mail_location = maildir/   mail_location = maildir/g' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#disable_plaintext_auth/disable_plaintext_auth/g' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/auth_mechanisms = plain/auth_mechanisms = plain login/g' /etc/dovecot/conf.d/10-auth.conf
sed -i '91s/#user = /user = postfix/g' /etc/dovecot/conf.d/10-master.conf
sed -i '92s/#group = /group = postfix/g' /etc/dovecot/conf.d/10-master.conf

systemctl enable dovecot
systemctl start dovecot

#Install and configure Squirrelmail / webmail
yum install squirrelmail -y
/usr/share/squirrelmail/config/conf.pl <<"EOF"
1
1
borrecloudservice
S

Q
EOF
/usr/share/squirrelmail/config/conf.pl << "EOF"
2
1
borrecloudservice.dk
S

Q
EOF
/usr/share/squirrelmail/config/conf.pl << "EOF"
3
2
S

Q
EOF

echo 'Alias /webmail /usr/share/squirrelmail' >> /etc/httpd/conf/httpd.conf
echo '<Directory /usr/share/squirrelmail>' >> /etc/httpd/conf/httpd.conf
 echo '  Options Indexes FollowSymLinks' >> /etc/httpd/conf/httpd.conf
 echo '  RewriteEngine On' >> /etc/httpd/conf/httpd.conf
 echo '  AllowOverride All' >> /etc/httpd/conf/httpd.conf
 echo '  DirectoryIndex index.php' >> /etc/httpd/conf/httpd.conf
 echo '  Order allow,deny' >> /etc/httpd/conf/httpd.conf
 echo '  Allow from all' >> /etc/httpd/conf/httpd.conf
echo '</Directory>' >> /etc/httpd/conf/httpd.conf

systemctl restart httpd
#!/bin/bash
mysql -u root << "EOF"

CREATE DATABASE wordpress;
CREATE USER admin@192.168.1.2 IDENTIFIED BY 'Kode1234!';
GRANT ALL ON wordpress.* TO admin@192.168.1.2 IDENTIFIED BY 'Kode1234!';
FLUSH PRIVILEGES;
quit;
EOF
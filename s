#!/bin/bash
apt update -y
apt install apache2 php mariadb-server php-mysql -y
systemctl start apache2
systemctl enable apache2
systemctl start mariadb
systemctl enable mariadb
mysql_secure_installation <<EOF

y
password
password
y
n
y
y
EOF
mysql -u root -ppassword <<EOF
CREATE DATABASE dvwa;
CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF
cd /var/www/html
rm -rf dvwa
git clone https://github.com/digininja/DVWA.git  dvwa
chown -R www-data:www-data dvwa
chmod -R 755 dvwa
cp dvwa/config/config.inc.php.dist dvwa/config/config.inc.php
sed -i 's/$_DVWA\[\'db_password\'\] = \'\';/$_DVWA[\'db_password\'] = \'password\';/' dvwa/config/config.inc.php
apt install rsyslog -y
echo "*.* @<IP_WAZUH_SERVER>:1514" >> /etc/rsyslog.conf
systemctl restart rsyslog
curl -so /etc/apt/trusted.gpg.d/wazuh.gpg https://packages.wazuh.com/key.gpg 
echo "deb https://packages.wazuh.com/4.x/apt/  stable main" | sudo tee -a /etc/apt/sources.list.d/wazuh.list
apt update && apt install wazuh-agent -y
sed -i "s/WAZUH_MANAGER=.*/WAZUH_MANAGER=<IP_WAZUH_SERVER>/g" /var/ossec/etc/ossec.conf
systemctl restart wazuh-agent

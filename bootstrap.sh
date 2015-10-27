#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='vagrant'
IP="192.168.33.22"
PROJECTFOLDER='myproject'
# set, if different from project folder
DATABASE=''

if [[ -z "$DATABASE" ]]; then
	DATABASE=${PROJECTFOLDER}
fi

# create project folder
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install apache 2.5 and php 5.5
sudo apt-get install -y apache2
sudo apt-get install -y php5

# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php5-mysql

# install phpmyadmin and give password(s) to installer
# for simplicity I'm using the same password for mysql and phpmyadmin
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

# setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/www/html/${PROJECTFOLDER}"
    <Directory "/var/www/html/${PROJECTFOLDER}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# enable mod_rewrite
sudo a2enmod rewrite

# restart apache
service apache2 restart

# install git
sudo apt-get -y install git

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


# create mysql database
echo "CREATE DATABASE IF NOT EXISTS ${DATABASE}" | mysql -uroot -p${PASSWORD}

# create index files
echo "<h1>Hello ${PROJECTFOLDER}!</h1>" >> /var/www/html/${PROJECTFOLDER}/index.html
echo "<p>Apache is running.<p>" >> /var/www/html/${PROJECTFOLDER}/index.html
echo "<p>Head over to <a href='index.php'>index.php</a> to see if php is working, too.</p>" >> /var/www/html/${PROJECTFOLDER}/index.html
echo "<?php phpinfo();" >> /var/www/html/${PROJECTFOLDER}/index.php

rm /var/www/html/index.html

echo "\n\nHead over to http://${IP} to see if apache is running."
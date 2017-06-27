#!/usr/bin/env bash

#--------------------------------------------------------------------------

echo "configuration du projet"
PASSWORD='1234'
PROJECTFOLDER='web-app'

#--------------------------------------------------------------------------

echo "création des dossiers du projet"
sudo mkdir "/var/vagrant-project"
sudo mkdir "/var/vagrant-project/${PROJECTFOLDER}"
sudo mkdir "/var/vagrant-project/${PROJECTFOLDER}/www"

#--------------------------------------------------------------------------

echo "Mise à jour de la base de dépôt des logiciels ubuntu"
sudo apt-get update
sudo apt-get -y upgrade

#--------------------------------------------------------------------------

echo "installation de php et Apache"
sudo apt-get install -y apache2
sudo apt-get install php 
sudo apt-get install php-xdebug -y
sudo apt-get install libapache2-mod-php7.0 php7.0-curl php7.0-json

#--------------------------------------------------------------------------

echo "installation de MySQL"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get -y install mysql-server
sudo apt-get install php-mysql

#--------------------------------------------------------------------------

echo "configuration de phpMyAdmin"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $PASSWORD"
sudo debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2"
sudo apt-get -y install phpmyadmin

#--------------------------------------------------------------------------

echo "configuration de l'hôte virtuel"
# Hôte virtuel
VHOST=$(cat <<EOF
<VirtualHost *:80>
    DocumentRoot "/var/vagrant-project/${PROJECTFOLDER}/www"
    <Directory "/var/vagrant-project/${PROJECTFOLDER}/www">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

#--------------------------------------------------------------------------

echo "gestion du fichier php.ini"
# Création d'un lien symbolique pour utiliser un fichier php.ini
# modifiable depuis la racine du projet

# suppression du fichier php.ini d'origine
sudo rm -f /etc/php/7.0/apache2/php.ini

# définition d'un alias qui pointe vers notre propre fichier php.ini
sudo ln -s 	/var/vagrant-project/conf/php.ini /etc/php/7.0/apache2/php.ini

#--------------------------------------------------------------------------

echo "activation de la réécriture d'url"
sudo a2enmod rewrite

#--------------------------------------------------------------------------

echo "redémarrage d'Apache"
service apache2 restart

#--------------------------------------------------------------------------

echo "installation de Git"
sudo apt-get -y install git

#--------------------------------------------------------------------------

echo "installation de Composer"
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

#--------------------------------------------------------------------------

echo "création de la base de données"
#mysql -u root -p$PASSWORD < /var/vagrant-project/conf/sql/db.sql
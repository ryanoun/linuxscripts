#!/bin/sh

# Requirements: Cent OS 7

# Installs nginx-latest + php-v7.3 + mariadb-v10.4
# Also includes composer-latest, nodejs-v12, git-latest

NGINX_ROOT_PATH=/var/www/html
NGINX_SERVER_NAME=somehost.host.io
MYSQL_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c12)
MYSQL_USER=passport
MYSQL_USER_PASSWORD=$(</dev/urandom tr -dc A-Za-z0-9 | head -c12)

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "#################################################################"
echo "# Server Installation "
echo "# MariaDB "
echo "# Nginx "
echo "# PHP 7.3 + FPM "
echo "# Git "
echo "# Composer "
echo "# Node "
echo "#################################################################"
echo ""
echo ""
echo ""

# SELINUX
sestatus

yum -y install policycoreutils-python

if [ -e "/etc/selinux/config" ]; then
	sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0
fi

sestatus

systemctl stop httpd
systemctl stop mysql

yum upgrade -y

yum -y update ca-certificates
yum -y install wget chkconfig epel-release nano net-tools rsync

yum -y erase apr httpd

#Fix epel ssl issue 
sed -i "s/mirrorlist=https/mirrorlist=http/" /etc/yum.repos.d/epel.repo

centosversion=`rpm -qa \*-release | grep -Ei "oracle|redhat|centos|cloudlinux" | cut -d"-" -f3`

echo 
echo "#######################################"
echo "# Installing MariaDB"
echo "#######################################"
echo
echo
# Install MariaDB
cat <<EOF | sudo tee -a /etc/yum.repos.d/MariaDB.repo
# MariaDB 10.4 CentOS repository list
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
EOF

yum install MariaDB-server MariaDB-client -y

systemctl enable mariadb

ln -s /etc/init.d/mysql	/etc/init.d/mysqld
systemctl start mariadb

mysqladmin -u root password $MYSQL_PASSWORD
mysql -u root -p$MYSQL_PASSWORD -e "DROP DATABASE test";
mysql -u root -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost'";
mysql -u root -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User=''";
mysql -u root -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES";

mysql -u root -p$MYSQL_PASSWORD -e "CREATE USER '"$MYSQL_USER"'@'localhost' IDENTIFIED BY '"$MYSQL_USER_PASSWORD"';";
mysql -u root -p$MYSQL_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '"$MYSQL_USER"'@'localhost';";
mysql -u root -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;";

# ADD SQL ROOT PASSWORD
cat > /root/.my.cnf <<EOF
[client]
password=$password
user=root
EOF

# SECURE SQL ROOT PASSWORD
chmod 600 /root/.my.cnf

# RESTART SQL TO ACCEPT THE NEW CHANGES
service mysqld restart

if [ ! -e "/var/lib/mysql" ];then
    echo "Installation FAILED at SQL !!!"
    exit 1
fi


# Setup Laravel NGINX
echo 
echo "#######################################"
echo "# NGINX"
echo "#######################################"
echo
echo
yum -y install nginx

wget https://raw.githubusercontent.com/ryanoun/linuxscripts/master/config/nginx/nginx.conf -O /etc/nginx/nginx.conf

sed -i 's~$SERVER_NAME~'"$NGINX_SERVER_NAME"'~g' /etc/nginx/nginx.conf
sed -i 's~$SERVER_ROOT~'"$NGINX_ROOT_PATH"'~g' /etc/nginx/nginx.conf

mkdir -p $NGINX_ROOT_PATH
mkdir -p /var/cache/nginx

chown -R nginx:nginx $NGINX_ROOT_PATH
chown -R nginx:nginx /var/cache/nginx

chmod 700 $NGINX_ROOT_PATH
chmod 700 /var/cache/nginx

systemctl start nginx
systemctl enable nginx

# Install PHP 7.3
echo 
echo "#######################################"
echo "# PHP 7.3"
echo "#######################################"
echo
echo
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
yum -y --enablerepo=remi-php73 install php

yum -y --enablerepo=remi-php73 install php-xml php-soap php-xmlrpc php-mbstring php-json php-gd php-mcrypt php-zip php-fpm php-pdo php-mysql php-mysql

sed -i 's/;cgi.fix_pathinfo/cgi.fix_pathinfo/g' /etc/php.ini

rm -rf /etc/php-fpm.d/www.conf

wget https://raw.githubusercontent.com/ryanoun/linuxscripts/master/config/php-fpm.d/www.conf -O /etc/php-fpm.d/www.conf

systemctl start php-fpm
systemctl enable php-fpm

# Firewall
echo 
echo "#######################################"
echo "# Firewall"
echo "#######################################"
echo
echo
firewall-cmd --list-all

firewall-cmd --add-service=http --permanent
firewall-cmd --reload

# Firewall
echo 
echo "#######################################"
echo "# Installing GIT"
echo "#######################################"
echo
echo
yum -y install git

# Composer
echo 
echo "#######################################"
echo "# Composer"
echo "#######################################"
echo
echo
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/bin --filename=composer

echo 
echo "#######################################"
echo "# Installing NODE"
echo "#######################################"
echo
echo
sudo yum install gcc-c++ make -y
curl -sL https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum install nodejs -y

echo 
echo "#######################################"
echo "# DONE "
echo "#######################################"
firewall-cmd --list-all
echo 
echo "MySQL Root Password: $MYSQL_PASSWORD"
echo
echo "MySQL User: $MYSQL_USER"
echo "MySQL User Password: $MYSQL_USER_PASSWORD"
echo 
nginx -v
echo 
mariadb --version
echo 
php -v
echo 
composer --version
echo 
git --version
echo 
echo "Node: $(node -v)"
echo 
echo "Please reboot the server!"
echo "Reboot command: shutdown -r now"

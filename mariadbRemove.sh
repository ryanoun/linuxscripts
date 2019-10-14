#!/bin/bash
# Remove MariaDB + Data from CentOS

systemctl stop mariadb.service
systemctl disable mariadb.service
yum remove MariaDB -y
rm -rf /var/lib/mysql/
rm -rf /etc/my.cnf.d/
rm -f /etc/my.cnf
rm -f /etc/yum.repos.d/MariaDB.repo
#!/bin/bash

touch /tmp/DB_created_from_zero

mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create user \"${REPLICATION_USER}\"@'%' identified by \"${REPLICATION_PASSWORD}\""
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "grant replication slave on *.* to 'replication'@'%'"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "GRANT REPLICATION CLIENT ON *.* to \"${MYSQL_USER}\"@'%'"
mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "use mysql; select * from user where User = \"${REPLICATION_USER}\""

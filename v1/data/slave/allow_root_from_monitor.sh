#!/bin/bash

mysql -u root -e "ALTER USER 'root'@'docker_whale_1.docker_default' IDENTIFIED BY 'root'"
mysql -u root -e "UPDATE mysql.user SET authentication_string=PASSWORD('root') WHERE User='root'"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root'"

mysql -u root -e "grant SUPER, GRANT OPTION, REPLICATION SLAVE, SELECT, RELOAD, DROP, CREATE, INSERT on *.* to 'root'@'%' identified by 'system'"

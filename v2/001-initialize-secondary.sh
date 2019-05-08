#!/bin/bash

touch /tmp/this_time_DB_created_from_zero

# mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "FLUSH PRIVILEGES"
# mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "create user \"${REPLICATION_USER}\"@'%' identified by \"${REPLICATION_PASSWORD}\""
# mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "grant replication slave on *.* to 'replication'@'%'"
# mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "use mysql; select * from user where User = \"${REPLICATION_USER}\""

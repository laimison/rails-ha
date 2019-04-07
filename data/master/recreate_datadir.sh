#!/bin/bash

kill `ps -ef | grep '/usr/sbin/mysqld' | awk '{print $2}'` 2>/dev/null
sleep 10
ps -ef
mv /data/master/db /data/master/db.$RANDOM
mkdir /data/master/db
mysqld --initialize-insecure
chmod -R 700 /data/master/db
chown -R mysql:mysql /data/master/db
/etc/init.d/mysql start
mysql -u root -e "update mysql.user set authentication_string=PASSWORD(\"password\") where User='root'; flush privileges;"

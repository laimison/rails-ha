#!/bin/bash

# Adding "fake" IP for master so Rails can start successfully, replica's DNS can be not resolved
echo '10.0.0.1 mysql-master' >> /etc/hosts
echo ' mysql-replica' >> /etc/hosts

while true
do
  IP1=`echo $MYSQL1 | grep -E "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" || host $MYSQL1 | grep 'has address' | awk '{print $NF}' | grep -v ^$ || echo " "`
  IP2=`echo $MYSQL2 | grep -E "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" || host $MYSQL2 | grep 'has address' | awk '{print $NF}' | grep -v ^$ || echo " "`

  # MySQL instance should respond with 0 for read_only to become a mysql-master,
  # otherwise assume this IP is mysql-replica
  (timeout 3 mysql -u ${MYSQL_USER} -p$MYSQL_PASSWORD -h $IP1 -s -N -e "SELECT @@global.read_only" 2>/dev/null | grep -q ^0$ && (sed "/mysql-master/c$IP1 mysql-master" /etc/hosts > /tmp/hosts && /bin/cp -f /tmp/hosts /etc/hosts)) || (sed "/mysql-replica/c$IP1 mysql-replica" /etc/hosts > /tmp/hosts && /bin/cp -f /tmp/hosts /etc/hosts)
  (timeout 3 mysql -u ${MYSQL_USER} -p$MYSQL_PASSWORD -h $IP2 -s -N -e "SELECT @@global.read_only" 2>/dev/null | grep -q ^0$ && (sed "/mysql-master/c$IP2 mysql-master" /etc/hosts > /tmp/hosts && /bin/cp -f /tmp/hosts /etc/hosts)) || (sed "/mysql-replica/c$IP2 mysql-replica" /etc/hosts > /tmp/hosts && /bin/cp -f /tmp/hosts /etc/hosts)

  sleep 10
done

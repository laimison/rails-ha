#!/bin/bash

while true
do
  # echo "iterating..."
  > /tmp/mysql-ip

  # Take only 2 instances
  for instance in $(echo $MYSQL_INSTANCES | sed "s/,/ /g" | awk '{print $1" "$2}')
  do
    if my_host=`host $instance 2>/dev/null`
    then
      echo $my_host | awk '{print $NF}' >> /tmp/mysql-ip
    else
      echo $instance | grep -E "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*" >> /tmp/mysql-ip
    fi
  done

  for ip in `cat /tmp/mysql-ip`
  do
    if ! timeout 5 mysql -u app -p$MYSQL_PASSWORD -h $ip -s -N -e "SELECT @@global.read_only" >/dev/null 2>/dev/null
    then
      echo "Error: not able to do SELECT queries on $ip"
    fi

    if timeout 5 mysql -u app -p$MYSQL_PASSWORD -h $ip -s -N -e "SELECT @@global.read_only" | grep -q ^0$
    then
      master=$ip
      replica=`cat /tmp/mysql-ip | grep -v ^$ip$ | head -n 1`
      echo "mysql-master at $master and mysql-replica at $replica"

      # Update entries if any changes in a cluster
      if ! cat /etc/hosts | grep mysql-master | grep -q $master
      then
        echo "Detected changes in a cluster so replacing $master mysql-master"
        cat /etc/hosts > /tmp/hosts && sed -i "/\smysql-master/d" /tmp/hosts && cat /tmp/hosts > /etc/hosts
        echo "$master mysql-master" >> /etc/hosts
      fi

      if ! cat /etc/hosts | grep mysql-replica | grep -q $replica
      then
        echo "Detected changes in a cluster so replacing $replica mysql-replica"
        cat /etc/hosts > /tmp/hosts && sed -i "/\smysql-replica/d" /tmp/hosts && cat /tmp/hosts > /etc/hosts
        echo "$replica mysql-replica" >> /etc/hosts
      fi

      # Add entries if not already exists
      if ! grep -q mysql-master /etc/hosts
      then
        echo "DNS records not found so adding $master mysql-master"
        echo "$master mysql-master" >> /etc/hosts
      fi

      if ! grep -q mysql-replica /etc/hosts
      then
        echo "DNS records not found so adding $replica mysql-replica"
        echo "$replica mysql-replica" >> /etc/hosts
      fi

      break # from for loop
    fi
  done

  sleep 10
done

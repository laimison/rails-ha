#!/bin/bash

case $1 in
  stop-slave)
  mysql -u root -ppassword -e "stop slave"
  ;;
  connect-to-master)
  mysql -u root -ppassword -e "change master to master_host='dolphin', master_port=33061, master_user='slaveuser', master_password='slavepassword'"
  ;;
  *)
  echo 'Usage:
stop-slave
connect-to-master'
esac

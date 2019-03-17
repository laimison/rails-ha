#!/bin/bash

case $* in
  status)
  mysqlrplshow --master=root:root@192.168.250.246:3306 --discover-slaves-login=root:root --verbose
  ;;
  install)
  echo 2
  ;;
  *)
  echo 'Usage: install, status'
  ;;
esac

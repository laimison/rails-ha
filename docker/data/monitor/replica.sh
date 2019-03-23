#!/bin/bash

case $* in
  status)
  mysqlrplshow --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose
  ;;
  health)
  mysqlfailover --force --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose health
  ;;
  failover)
  mysqlfailover --force --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose auto
  echo "Now the tool is monitoring the health so master can go down..."
  ;;
  *)
  echo 'Usage: status, health, failover'
  ;;
esac

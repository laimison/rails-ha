#!/bin/bash

case $* in
  status)
  mysqlrplshow --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose
  ;;
  install)
  echo 2
  ;;
  *)
  echo 'Usage: install, status'
  ;;
esac

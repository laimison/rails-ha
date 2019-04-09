#!/bin/bash

case $1 in
  masterdump)
  mysqldump -u root -ppassword --all-databases --master-data --flush-privileges > /data/master/backup/masterdump.sql
  ;;
  *)
  echo 'Usage:
masterdump - does mysqldump to masterdump.sql'
  ;;
esac

#!/bin/bash

mysqldump -u root -ppassword --all-databases --master-data --flush-privileges > /data/master/backup/masterdump.sql

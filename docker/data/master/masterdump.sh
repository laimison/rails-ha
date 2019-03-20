#!/bin/bash

mysqldump -u root --all-databases --master-data --flush-privileges > /data/master/backup/masterdump.sql

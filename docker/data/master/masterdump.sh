#!/bin/bash

mysqldump -u root --all-databases --master-data > /data/master/masterdump.sql

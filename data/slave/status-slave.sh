#!/bin/bash

mysql -u root -ppassword -e "show slave status\G;"
ls -l /data/slave/db/slave*

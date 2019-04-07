#!/bin/bash

mysql -u root -e "show slave status\G;"
ls -l /data/slave/db/slave*

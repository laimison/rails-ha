#!/bin/bash

mysql -u root -e "start slave"
mysql -u root -e "show slave status\G;"

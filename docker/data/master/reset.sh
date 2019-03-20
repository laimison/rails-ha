#!/bin/bash

mysql -u root -e "reset master"
mysql -u root -e "flush tables with read lock"
mysql -u root -e "show master status"

#!/bin/bash

mysql -u root -e "change master to master_host='172.24.0.3', master_port=33061, master_user='slaveuser', master_password='slavepassword'"

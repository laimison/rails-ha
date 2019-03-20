#!/bin/bash

# mysql -u root -e "change master to master_host='dolphin', master_port=33061, master_user='slaveuser', master_password='slavepassword', master_auto_position=1"
mysql -u root -e "change master to master_host='dolphin', master_port=33061, master_user='slaveuser', master_password='slavepassword'"

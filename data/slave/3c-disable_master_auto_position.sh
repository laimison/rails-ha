#!/bin/bash

mysql -u root -ppassword -e "change master to master_auto_position=0"

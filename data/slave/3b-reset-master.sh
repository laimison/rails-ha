#!/bin/bash

# This can reset @@GLOBAL.GTID_EXECUTED
mysql -u root -ppassword -e "reset master"

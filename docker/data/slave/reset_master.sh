#!/bin/bash

# This can reset @@GLOBAL.GTID_EXECUTED
mysql -u root -e "reset master"

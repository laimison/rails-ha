#!/bin/bash

mysql -u root -ppassword -e "insert into animals.list values (\"`shuf -n1 -e crab medusa seal`\")"

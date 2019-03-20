#!/bin/bash

mysql -u root -e "insert into animals.list values (\"`shuf -n1 -e crab medusa seal`\")"

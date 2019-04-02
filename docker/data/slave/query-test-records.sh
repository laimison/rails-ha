#!/bin/bash

mysql -u root -ppassword -e "select * from animals.list"
mysql -u root -ppassword -e "select * from testdb.examples"

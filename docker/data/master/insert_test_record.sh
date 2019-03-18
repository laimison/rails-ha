#!/bin/bash

mysql -u root -e "insert into pets.cats values ('fluffy')"
mysql -u root -e "select * from pets.cats"

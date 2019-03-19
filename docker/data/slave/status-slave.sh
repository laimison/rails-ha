#!/bin/bash

mysql -u root -e "show slave status\G;"

#!/bin/bash

mysql -u root -e "change master to master_auto_position=0"

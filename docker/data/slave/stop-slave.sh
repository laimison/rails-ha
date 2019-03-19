#!/bin/bash

mysql -u root -e "STOP SLAVE IO_THREAD FOR CHANNEL ''"
mysql -u root -e "stop slave"

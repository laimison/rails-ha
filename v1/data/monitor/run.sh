#!/bin/bash

case $* in
  connect-to-master)
  mysql -u root -ppassword -P 33061 -h dolphin
  ;;
  status)
  mysqlrplshow --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose
  ;;
  health)
  mysqlfailover --force --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose health
  ;;
  auto)
  mysqlfailover --force --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose --exec-after= auto
  # mysqlfailover –verbose –master=root@10.52.201.11 –discover-slaves-login=root –failover-mode=auto –candidates=root@10.52.201.101,root@10.206.75.34 –daemon=start –log=mysqlfailover.log –pidfile=failover_daemon.pid
  echo "Now the tool is monitoring the health so master can go down..."
  ;;
  add-master-back-as-slave)
  mysqlreplicate --master=root:password@goldfish:33062 --slave=root:password@dolphin:33061 --rpl-user=slaveuser:slavepassword
  ;;
  status-transition)
  mysqlrplshow --master=root:password@goldfish:33062 --discover-slaves-login=root:password --verbose
  ;;
  health-transition)
  mysqlfailover --force --master=root:password@goldfish:33062 --discover-slaves-login=root:password --verbose health
  ;;
  switchover)
  mysqlrpladmin --master=root:password@goldfish:33062 --new-master=root:password@dolphin:33061 --demote-master --discover-slaves-login=root:password --rpl-user=slaveuser:slavepassword --verbose --exec-after= switchover
  ;;
  *)
  echo 'Usage:
  connect-to-master - access mysql on original master
  status - see cluster status
  health - monitor cluster health
  auto - turn on automated mysqlfailover checker
  add-master-back-as-slave - add failed master as slave
  status-transition - cluster status when failed master running as slave
  health-transition - cluster health when failed master running as slave (doesnt work in most of the cases)
  switchover - switch back to original config by restoring master'
  ;;
esac

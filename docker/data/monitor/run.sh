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
  mysqlfailover --force --master=root:password@dolphin:33061 --discover-slaves-login=root:password --verbose auto
  # mysqlfailover –verbose –master=root@10.52.201.11 –discover-slaves-login=root –failover-mode=auto –candidates=root@10.52.201.101,root@10.206.75.34 –daemon=start –log=mysqlfailover.log –pidfile=failover_daemon.pid
  echo "Now the tool is monitoring the health so master can go down..."
  ;;
  add-master-back-as-slave)
  mysqlreplicate --master=root:password@goldfish:33062 --slave=root:password@dolphin:33061 --rpl-user=slaveuser:slavepassword
  ;;
  switchover)
  mysqlrpladmin --master=root:password@goldfish:33062 --new-master=root:password@dolphin:33061 --demote-master --discover-slaves-login=root:password --rpl-user=slaveuser:slavepassword --verbose switchover
  ;;
  *)
  echo 'Usage:
  connect-to-master - access mysql on master
  status - see cluster status
  health - monitor cluster health
  auto - turn on automated mysqlfailover checker
  add-master-back-as-slave - add failed master as slave
  switchover - switch back to original config by restoring master'
  ;;
esac

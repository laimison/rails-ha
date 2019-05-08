# Rails & MySQL High Availability

Ensuring working replication, automatic failover, manual slave restoring and optional switchover

## Initialise

Steps before leaving high availability for production

### Recreate DB from Zero

```
docker-compose down; rm -rf data/primary/*; rm -rf data/secondary/*; docker-compose build; docker-compose up -d
```

### Connect Second DB as Slave to Master

1) Stop auto failover

```
docker exec -it mysql-monitor bash -c "killall sleep mysqlfailover"
docker exec -it mysql-monitor bash -c "ps -ef -ww"
```

2) Create the table

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; create table test (id INT NOT NULL AUTO_INCREMENT, name varchar(20), PRIMARY KEY (id))"'
```

3) Check current topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

4) Connect Second DB to Master

Method A - Simply Connect to Master (enabling GTID - MASTER_AUTO_POSITION=1) - Preferred Method

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT * FROM mysql.gtid_executed"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CHANGE MASTER TO MASTER_HOST=\"mysql-1\", MASTER_PORT=3306, MASTER_USER=\"replication\", MASTER_PASSWORD=\"${REPLICATION_PASSWORD}\", MASTER_AUTO_POSITION=1"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "START SLAVE"'
# replication and app users should be created now
```

Method B - Using Dump

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "stop slave"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-1\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-2 bash -c 'mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql-1 --all-databases --master-data --flush-privileges > /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'ls -l /tmp'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
# docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

Method C - not confirmed

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
docker exec -it mysql-monitor bash -c 'mysqlreplicate --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --slave=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

5) Check Current Topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

6) Check Whether Replication Worked

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker-compose down && docker-compose up -d
docker exec -it mysql-monitor bash -c "ps -ef -ww" # if this is monitoring, it's fine
docker logs -f mysql-monitor
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

## Test When Slave is Down

Usually to not have running slave is a simple issue, but just in case testing it...

```
docker logs -f mysql-monitor
docker stop mysql-2
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker start mysql-2
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

## Test When Master is Down

The test case is:

* Turn off master down

* Slave automatically becomes a new master in seconds

* Turn on the original master

1) Check the topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

2) Watch logs in another terminal

```
docker logs -f mysql-monitor
```

3) Stop master, wait for few seconds for failover to happen, write some records to slave, restore the original master, stop mysqlfailover utility and check the status

```
docker stop mysql-1

# wait here...

docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'

docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'

docker start mysql-1

docker exec -it mysql-monitor bash -c "killall sleep mysqlfailover"
docker exec -it mysql-monitor bash -c "ps -ef -ww"

docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset slave all"'
docker exec -it mysql-monitor bash -c 'mysqlreplicate --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --slave=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "STOP SLAVE IO_THREAD FOR CHANNEL \"\""'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-2\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'

docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

If received an error:

```
ERROR: Error performing commit: 1776 (HY000): Parameters MASTER_LOG_FILE, MASTER_LOG_POS, RELAY_LOG_FILE and RELAY_LOG_POS cannot be set when MASTER_AUTO_POSITION is active.
```

Solve this issue:

Method A

```
# docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset slave all"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset slave all"'
# docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'
# docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'

mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

Method B

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "stop slave"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-2\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-1 bash -c 'mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql-2 --all-databases --master-data --flush-privileges > /tmp/master-dump-mysql-2.sql'
docker exec -it mysql-1 bash -c 'ls -l /tmp'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/master-dump-mysql-2.sql'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

Received an error:

```
ERROR 1776 (HY000) at line 31: Parameters MASTER_LOG_FILE, MASTER_LOG_POS, RELAY_LOG_FILE and RELAY_LOG_POS cannot be set when MASTER_AUTO_POSITION is active.
```

Solved with:

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'
```

Received an error:

```
ERROR 1840 (HY000) at line 24: @@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty.
```

Solved with:

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
```

Continuing on Method B

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose
```

4) Test if slave successfully replicated

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker-compose stop mysql-1 && docker-compose stop mysql-2 && docker-compose start mysql-1 && docker-compose start mysql-2
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

### Switchover

Received an error:

```
ERROR: Slave mysql-1:3306 did not catch up to the master.
```

Solving this issue:

- Make sure that slave is in sync

Continuing on switchover:

```
mysqlrpladmin --master=root:${MYSQL_ROOT_PASSWORD}@mysql-2:3306 --new-master=root:${MYSQL_ROOT_PASSWORD}@mysql-1:3306 --demote-master --discover-slaves-login=root:${MYSQL_ROOT_PASSWORD} --rpl-user=replication:${REPLICATION_PASSWORD} --verbose --exec-after=/tmp/mysqlswitchover_exec_after.sh switchover
```

Received an error:

```
Executing start on slave mysql-2:3306 WARN - slave is not configured with this master
```

Solving this issue:

```
mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose

docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "STOP SLAVE IO_THREAD FOR CHANNEL \"\""'

```

Received an error:

```
mysql.connector.errors.OperationalError: MySQL Connection not available.
```

Solving this issue:

```
killall mysqlfailover
ps -ef
mysqlrpladmin --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --new-master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose switchover
```

Continuing:

```
mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose
```

Slave wasn't printed so solving this issue:

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "stop slave"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-1\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-2 bash -c 'mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql-1 --all-databases --master-data --flush-privileges > /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'ls -l /tmp'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

Another method to sync slave:

```
mysqlreplicate --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --slave=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'

mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

## Restore mysqlfailover

```
docker stop mysql-monitor
docker-compose up -d mysql-monitor
```

## Troubleshooting

* Check `docker logs -f mysql-*`

* Wait more time between steps when doing DB changes

* Experiment with commands `stop` or `reset` for `slave` or `master`

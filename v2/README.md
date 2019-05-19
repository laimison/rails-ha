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

2) Create the table (test table is not for Rails so can be skipped)

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; create table test (id INT NOT NULL AUTO_INCREMENT, name varchar(20), PRIMARY KEY (id))"'
```

3) Check current topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

4) Connect Second DB to Master

Method A - Simply Connect to Master (enabling GTID - MASTER_AUTO_POSITION=1) - Good Method

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT * FROM mysql.gtid_executed"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CHANGE MASTER TO MASTER_HOST=\"mysql-1\", MASTER_PORT=3306, MASTER_USER=\"replication\", MASTER_PASSWORD=\"${REPLICATION_PASSWORD}\", MASTER_AUTO_POSITION=1"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "START SLAVE"'
# replication and app users should be created now
```

Method B - mysqlreplicate - Good Method

```
docker exec -it mysql-monitor bash -c 'mysqlreplicate --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --slave=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
```

Method C - Using Dump (last resort if nothing worked)

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "stop slave"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-1\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-2 bash -c 'mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql-1 --all-databases --master-data --flush-privileges > /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'ls -l /tmp'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "reset master"'
# docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_auto_position=0"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/master-dump-mysql-1.sql'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
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

## Test When Slave is Down (Optional)

Usually to not have running slave is a simple issue, but just in case testing it...

```
docker logs -f mysql-monitor
docker stop mysql-2
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker start mysql-2
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

## Test When Master is Down (Failover)

The test case is:

* Turn off master down

* Slave automatically becomes a new master in seconds

* Turn on the original master

1) Check the topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

2) Watch logs in another terminal & Make sure mysqlfailover is running

```
# you may need to do: docker restart mysql-monitor
docker logs -f mysql-monitor
```

3) Kill master immediately, wait for few seconds for failover to happen

```
docker kill --signal=SIGKILL mysql-1
# wait here...
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = OFF;"'
```

4) write some records to slave and restore the original master

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'

docker start mysql-1
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}"'
```

5) stop mysqlfailover

```
docker exec -it mysql-monitor bash -c "killall sleep mysqlfailover"
docker exec -it mysql-monitor bash -c "ps -ef -ww"
```

## Sync Original Master as Slave (After Failover)

1) Check current topology and see logs in another window

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
docker logs -f mysql-1
```

2) Sync Original Master as Slave

Method A - connect to master

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-2\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\", MASTER_AUTO_POSITION=1"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

Method B - mysqlreplicate

```
docker exec -it mysql-monitor bash -c 'mysqlreplicate --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --slave=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --rpl-user=replication:${REPLICATION_PASSWORD} --verbose'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

Method C - mysqldump (last resort if nothing worked)

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "stop slave"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-2\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\""'
docker exec -it mysql-1 bash -c 'mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" -h mysql-2 --all-databases --master-data --flush-privileges > /tmp/master-dump-mysql-2.sql'
docker exec -it mysql-1 bash -c 'ls -l /tmp'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" < /tmp/master-dump-mysql-2.sql'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'
```

3) Test if slave successfully replicated

```
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker-compose stop mysql-1 && docker-compose stop mysql-2 && docker-compose start mysql-1 && docker-compose start mysql-2
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; insert into test(name) values (\"`shuf -n1 -e crab medusa seal`\")"'
# wait some time to replicate
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from test;"'
```

### Switchover

1) Check current topology

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

2) Switchover (freeze writes) - run both commands at the same time

```
docker exec -it mysql-monitor bash -c 'mysqlrpladmin --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-2:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --new-master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --rpl-user=replication:"${REPLICATION_PASSWORD}" --verbose switchover'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
```

or

```
docker exec -it mysql-monitor bash -c 'mysqlrpladmin --master=root:example@mysql-2:3306 --new-master=root:example@mysql-1:3306 --discover-slaves-login=root:example --rpl-user=replication:example --verbose switchover'
```

3) Check status

```
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'
```

4) Restart mysqlfailover

```
docker restart mysql-monitor
```

5) Connect original slave to original master (enable writes)

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = OFF;"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CHANGE MASTER TO MASTER_HOST=\"mysql-1\", MASTER_PORT=3306, MASTER_USER=\"replication\", MASTER_PASSWORD=\"${REPLICATION_PASSWORD}\", MASTER_AUTO_POSITION=1"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "START SLAVE"'
```

6) Restore node on CDN load balancer (optional)

```
# Usually send API PUT request ...
```


7) Check status

```
docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT @@global.read_only"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT @@global.read_only"'

docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from examples"'
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "use my-app; select * from examples"'

docker exec -it rails bash -c "cat /etc/hosts | grep mysql; host mysql-1; host mysql-2; lsof -i -P"
docker exec -it mysql-monitor bash -c 'mysqlrplshow --master=root:"${MYSQL_ROOT_PASSWORD}"@mysql-1:3306 --discover-slaves-login=root:"${MYSQL_ROOT_PASSWORD}" --verbose'

docker logs -f mysql-monitor
```

## Change DNS

List DNS records

```
docker exec -it rails bash -c "cat /etc/hosts; host mysql-1; host mysql-2"
```

Delete mysql DNS records

```
docker exec -it rails bash -c "cat /etc/hosts > /tmp/hosts && sed -i \"/\smysql-/d\" /tmp/hosts && cat /tmp/hosts > /etc/hosts"
```

If mysql-1 becoming master and mysql-2 is left as replica

```
docker exec -it rails bash -c "host mysql-1 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-master\" | tee -a /etc/hosts; done"
docker exec -it rails bash -c "host mysql-2 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-replica\" | tee -a /etc/hosts; done"
```

OR

If mysql-2 becoming master and mysql-1 is left as replica

```
docker exec -it rails bash -c "host mysql-2 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-master\" | tee -a /etc/hosts; done"
docker exec -it rails bash -c "host mysql-1 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-replica\" | tee -a /etc/hosts; done"
```

Verify

```
docker exec -it rails bash -c "cat /etc/hosts; host mysql-1; host mysql-2"
```

Check opened connections

```
docker exec -it rails bash -c "lsof -i -P"
docker exec -it rails bash -c "ping -c 3 mysql-master"
docker exec -it rails bash -c "ping -c 3 mysql-replica"
```

## Restore mysqlfailover

```
docker stop mysql-monitor
docker-compose up -d mysql-monitor
docker logs -f mysql-monitor
```

## An example to test service if responding

```
python3 -m http.server 8000 --bind 192.168.2.100
```

## Reach host on Mac OS

```
ping host.docker.internal
```

First one is localhost and second one is WiFi address

## Troubleshooting

* Check `docker logs -f mysql-*`

* Wait more time between steps when doing DB changes

* Experiment with commands `stop` or `reset` for `slave` or `master`

# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Rails

Run

```
rails s
```

Access page [localhost:3000](http://localhost:3000)

## MySQL

Run

```
cd docker
./run.sh
```

## Building container

Build and run container separately

```
cd docker
docker-compose build orca
docker-compose up -d orca
docker-compose ps
docker exec -it docker_orca_1 /bin/bash
```

or

```
docker-compose up -d --build orca
```

or

```
docker build -t rails -f Dockerfile-rails .
docker run -it rails /bin/bash
```

## Failover

It's automatic, but triggered once. If failover happened, you need to do switchover manually.

Simulate failover:

```
docker exec -it rails-ha_dolphin_1 /etc/init.d/mysql stop
```

## Switchover

Simulate that instance become available:

```
docker exec -it rails-ha_dolphin_1 /etc/init.d/mysql start
```

Add original master back as slave:

```
docker exec -it rails-ha_whale_1 ./run.sh add-master-back-as-slave
docker exec -it rails-ha_whale_1 ./run.sh status-transition
```

Turn off master DNS for writing on the app side:

```
docker exec -it rails-ha_orca_1 cat /etc/hosts
docker exec -it rails-ha_orca_1 bash -c "host dolphin | awk '{print \$NF}'"
docker exec -it rails-ha_orca_1 bash -c "cat /etc/hosts > /tmp/hosts && sed -i '/\smaster/d' /tmp/hosts && cat /tmp/hosts > /etc/hosts"
docker exec -it rails-ha_orca_1 bash -c "iptables -t nat -L OUTPUT"
docker exec -it rails-ha_orca_1 bash -c "iptables -t nat -D OUTPUT -d goldfish -p tcp --dport 33061 -j DNAT --to-destination :33062"
docker exec -it rails-ha_orca_1 host master
docker exec -it rails-ha_orca_1 nc -v goldfish 33061
docker exec -it rails-ha_orca_1 tail -f log/development.log
```

Before restoring master, make sure that data is replicated:

```
docker exec -it rails-ha_dolphin_1 mysql -u root -ppassword -e 'use testdb; select * from examples'
docker exec -it rails-ha_goldfish_1 mysql -u root -ppassword -e 'use testdb; select * from examples'
```

Switchover:

```
docker exec -it rails-ha_whale_1 ./run.sh switchover
docker exec -it rails-ha_whale_1 ./run.sh status-transition
docker exec -it rails-ha_whale_1 ./run.sh status
docker exec -it rails-ha_whale_1 bash -c "host dolphin; host goldfish"
```

If slave wasn't printed as part of topology:

```
docker exec -it rails-ha_dolphin_1 ./run.sh masterdump
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "stop slave"'
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "change master to master_host=\"dolphin\", master_port=33061, master_user=\"slaveuser\", master_password=\"slavepassword\""'
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword < /data/master/backup/masterdump.sql'
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "start slave"'
```

If issue '@@GLOBAL.GTID_PURGED can only be set when @@GLOBAL.GTID_EXECUTED is empty':

```
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "reset master"'
```

Some other commands might be needed if any issues:

```
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "change master to master_auto_position=0"'
docker exec -it rails-ha_goldfish_1 bash -c 'mysql -u root -ppassword -e "STOP SLAVE IO_THREAD FOR CHANNEL \"\""'
```

Restore app:

```
docker exec -it rails-ha_orca_1 host master
docker exec -it rails-ha_orca_1 ping -c 1 master
docker exec -it rails-ha_orca_1 host dolphin
docker exec -it rails-ha_orca_1 tail -f log/development.log
docker exec -it rails-ha_orca_1 cat /etc/hosts
docker exec -it rails-ha_orca_1 bash -c "echo \`host dolphin | awk '{print \$NF}'\` master | tee -a /etc/hosts"
docker exec -it rails-ha_orca_1 cat /etc/hosts
docker exec -it rails-ha_orca_1 /etc/init.d/nscd restart
docker exec -it rails-ha_orca_1 bash -c "rake tmp:clear"
```

Some debugging:

```
docker exec -it rails-ha_orca_1 lsof -n -i -P
```

...at this point I had to restart Rails to pick up new configuration... only this solution worked...

```
docker exec -it rails-ha_orca_1 bash -c "ps -ef -ww"
docker exec -it rails-ha_orca_1 bash -c "ps -ef | grep puma | grep rails | head -n 1 | awk '{print \$2}' > /tmp/pid; kill \`cat /tmp/pid\`"
docker exec -it rails-ha_orca_1 bash -c 'nohup rails s &> /tmp/out & sleep 1'
```

## References

### MySQL

[mysql in k8s](https://medium.com/@zzdjk6/step-by-step-setup-gtid-based-mysql-replica-and-automatic-failover-with-mysqlfailover-using-docker-489489d2922)

[mysql-utilities practical discussion](http://www.clusterdb.com/mysql/replication-and-auto-failover-made-easy-with-mysql-utilities)

[slave read-only mode](https://dba.stackexchange.com/questions/30128/should-a-mysql-replication-slave-be-set-to-read-only)

[configuration generator](https://tools.percona.com/wizard)

[full step-by-step procedure to resync a master-slave replication](https://stackoverflow.com/questions/2366018/how-to-re-sync-the-mysql-db-if-master-and-slave-have-different-database-incase-o)

[percona mysql solution to create/restore slave](https://www.percona.com/blog/2013/02/08/how-to-createrestore-a-slave-using-gtid-replication-in-mysql-5-6/)

[some useful details about mysql read_only real-time setting, VIP host, etc.](https://blog.isao.co.jp/mysqlfailover_dtest/)

[makara](https://github.com/taskrabbit/makara)

[distribute_reads](https://github.com/ankane/distribute_reads)

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

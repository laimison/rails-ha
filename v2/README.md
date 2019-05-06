# Rails & MySQL High Availability

Ensuring replication and failover

## Create empty DB

If you want to start with fresh DB, do the following:

```
docker-compose down
rm -rf data/primary/*
rm -rf data/secondary/*
```

A note that scripts in `/docker-entrypoint-initdb.d/` will be executed to initialize access, etc.

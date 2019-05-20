#!/bin/bash

echo "`date` Running Commands After MySQL Failover"

# echo "Remove node-1 from CDN pool"
# curl -vsX GET "${CDN_API_ADDRESS}" -H "Content-Type: application/json" -H "X-Auth-Email: ${CDN_AUTH_EMAIL}" -H "X-Auth-Key: ${CDN_AUTH_KEY}" | jq .result > /tmp/CDN.json
# logic to replace true to false in /tmp/CDN.json
# curl -vsX PUT ${CDN_API_ADDRESS} -H "Content-Type: application/json" -H "X-Auth-Email: ${CDN_AUTH_EMAIL}" -H "X-Auth-Key: ${CDN_AUTH_KEY}" -d @/tmp/CDN.json
# sleep 10

echo "Enable read-write on new master"
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = OFF;"'
sleep 10

# echo "Update mew master DNS record, remove slave"
# docker exec -it rails bash -c "cat /etc/hosts > /tmp/hosts && sed -i \"/\smysql-/d\" /tmp/hosts && cat /tmp/hosts > /etc/hosts"
# docker exec -it rails bash -c "host mysql-2 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-master\" | tee -a /etc/hosts; done"
# sleep 10

echo "When original master becomes available, make it read-only"
while true
do
  if ping -c 10 mysql-1 2>/dev/null | grep '% packet loss' | awk -F '%' '{print $1}' | awk '{print $NF}' | grep "^0$"
  then
    echo "Original master become available!"

    echo "Make it as read-only instance"
    docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'
    # docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT @@global.read_only"'

    # echo "Here is the place for dump" | tee /dev/console | tee -a /tmp/mysqlfailover.log

    # echo "Connect as slave to new master" | tee /dev/console | tee -a /tmp/mysqlfailover.log
    # docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "change master to master_host=\"mysql-2\", master_port=3306, master_user=\"replication\", master_password=\"${REPLICATION_PASSWORD}\", MASTER_AUTO_POSITION=1"'

    # echo "Start Slave" | tee /dev/console | tee -a /tmp/mysqlfailover.log
    # docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "start slave"'

    # echo "Update DNS as mysql-replica" | tee /dev/console | tee -a /tmp/mysqlfailover.log
    # docker exec -it rails bash -c "host mysql-1 | awk '{print \$NF}' | while read -r line; do echo \"\$line mysql-replica\" | tee -a /etc/hosts; done"
    break
  else
    echo "Original master is down. Waiting for the next iteration..."
  fi
  sleep 30
done

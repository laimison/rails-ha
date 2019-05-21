#!/bin/bash

echo "`date` Running Commands After MySQL Failover"

# echo "Remove node-1 from CDN pool"
# curl -vsX GET "${CDN_API_ADDRESS}" -H "Content-Type: application/json" -H "X-Auth-Email: ${CDN_AUTH_EMAIL}" -H "X-Auth-Key: ${CDN_AUTH_KEY}" | jq .result > /tmp/CDN.json
# logic to replace true to false in /tmp/CDN.json
# curl -vsX PUT ${CDN_API_ADDRESS} -H "Content-Type: application/json" -H "X-Auth-Email: ${CDN_AUTH_EMAIL}" -H "X-Auth-Key: ${CDN_AUTH_KEY}" -d @/tmp/CDN.json
# sleep 10

echo "Enable read-write on new master"
docker exec -it mysql-2 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = OFF;"'

echo "When original master becomes available, make it read-only"
sleep 10
while true
do
  if ping -c 10 mysql-1 2>/dev/null | grep '% packet loss' | awk -F '%' '{print $1}' | awk '{print $NF}' | grep "^0$"
  then
    echo "Original master become available!"

    echo "Make it as read-only instance"
    docker exec -it mysql-1 bash -c 'mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "SET GLOBAL read_only = ON;"'

    break
  else
    echo "Original master is down. Waiting for the next iteration..."
  fi
  sleep 10
done

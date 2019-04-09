#!/bin/bash

# Functions
is_master_available () {
  timeout 60 mysql -u root -ppassword -h dolphin -P 33061 -e 'show databases' > /dev/null
}

ip_from_master_host () {
  host dolphin | awk '{print $NF}' | grep -E '^[0-9]+\.'
}

# After restart assign master
while true
do
  if ip_from_master_host
  then
    echo "`ip_from_master_host` master '# dolphin'" >> /etc/hosts
    break
  fi
done

sleep 10

# If master becomes unavailable, switch to new master
while true
do
  if is_master_available || (sleep 5; is_master_available) || (sleep 5; is_master_available)
  then
    echo ""
  else
    new_master_ip=`host goldfish | awk '{print $NF}'`

    if echo $new_master_ip | grep -E '[0-9]+\.'
    then
      echo "$new_master_ip master"
      cat /etc/hosts > /tmp/hosts && sed -i "/\smaster/d" /tmp/hosts && cat /tmp/hosts > /etc/hosts && echo "$new_master_ip master '# goldfish with iptables rule'" >> /etc/hosts

      # This is needed only because doing tests on the same host
      iptables -t nat -I OUTPUT -d $new_master_ip -p tcp --dport 33061 -j DNAT --to-destination :33062
      exit 0
      # So at this stage manual switchover is needed ...
    fi
  fi

  sleep 5
done

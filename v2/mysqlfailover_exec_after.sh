#!/bin/bash

echo "******************* $0 script executed ********************" > /dev/stdout
echo "******************* $0 script executed ********************" > /dev/console
touch /tmp/mysqlfailover_happened

# Disable origin in load balancer
# Replace VIP DNS - make sure Rails refreshed as well

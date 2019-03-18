#!/bin/bash

containers () {
  containers=`docker-compose ps | awk '{print $1}' | tail -n +3`; for c in $containers; do docker exec -it $c bash; done
}

case $* in
  build)
    docker-compose down && docker-compose ps && docker-compose build && docker-compose up -d && docker-compose ps
    containers
    ;;
  login)
    containers
    ;;
  *)
    echo 'Usage: build, login'
    ;;
esac

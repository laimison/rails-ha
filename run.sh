#!/bin/bash

containers () {
  containers=`docker-compose ps | awk '{print $1}' | tail -n +3`
  for c in $containers
  do
    docker exec -it $c bash
  done
}

case $* in
  build)
    docker-compose down && docker-compose build && docker-compose up -d && docker-compose ps
    ;;
  build-no-cache)
    docker-compose down && docker-compose build --no-cache && docker-compose up -d && docker-compose ps
    ;;
  exec)
    containers
    ;;
  ps)
    docker-compose ps
    ;;
  *)
    echo 'Usage:
    build - down & build & up docker containers from Dockerfile
    build-no-cache - down & build --no-cache && up docker containers from Dockerfile
    exec - bash login to all containers one by one
    ps - list running docker containers'
    ;;
esac

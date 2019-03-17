#!/bin/bash

name=dolphin

docker-compose ps

case $* in
  build)
    docker-compose build && docker-compose up -d
    ;;
  login)
    docker-compose ps $name 2>/dev/null | grep -q $name || docker-compose up -d
    echo "test"
    docker-compose run $name /bin/bash
    ;;
  delete)
    docker-compose rm -s -f $name
    ;;
  *)
    echo 'Usage: build, login, delete'
    ;;
esac

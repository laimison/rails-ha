#!/bin/bash

echo "Open page: http://localhost:3000/v1/examples" && echo

case $* in
  s)
  rails s
  ;;
  *)
  echo "Usage: s"
  ;;
esac

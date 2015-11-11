#!/bin/bash
if [ $# -ne 4 ]; then
  # Print usage
  echo 'wrong!!! bad operator!!!
  usage:
  mkcivi.sh NAME TYPE PORT ADMINPASS
  e.g.
  mkcivi.sh mycivi drupal-demo 8001 secret123
  '
  exit 1
fi
echo "
my Name is $1 and my type is $2
the url is http://localhost:$3
the admin password will be set to $4
"

civibuild create $1 --type $2 -clean --civi-ver 4.6 --url http://localhost:$3 --admin-pass $4

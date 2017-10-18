#!/bin/sh

ssl_redirects_fiilepath='/etc/haproxy/ssl-redirects.lst'

if [ -z "$1" ]; then
  echo "usage: $0 rsync_path_to_ssl_redirect_folder"
  echo "example:"
  echo "$0 \"root@192.168.33.21:/storage/configuration\""
  exit 1
fi

old_hash=$(md5sum "$ssl_redirects_fiilepath")

rsync -z -e "ssh -o StrictHostKeyChecking=no" "$1"/ssl-redirects.lst /etc/haproxy 

new_hash=$(md5sum "$ssl_redirects_fiilepath")

if [ "$old_hash" != "$new_hash" ]; then
  echo "OK: new ssl redirects loaded, reloading haproxy"
  /etc/init.d/haproxy reload 
fi

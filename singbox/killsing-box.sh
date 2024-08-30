#!/bin/bash
r=$(ps aux | grep cloudflare | grep -v grep | awk '{print $2}')

if [ -z "$r" ]; then
  echo "can't find cloudflare" >/dev/null
else
  echo $r
  kill -9 $r
fi

r=$(ps aux | grep serv00sb | grep -v grep | awk '{print $2}')

if [ -z "$r" ]; then
  echo "can't find serv00sb" >/dev/null
else
  echo $r
  kill -9 $r
fi

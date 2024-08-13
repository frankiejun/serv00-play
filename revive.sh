#!/bin/bash

sendtype=$SENDTYPE
#HOSTS_JSON='{
#"info": [
#{
#  "host": "s2.serv00.com",
#  "username": "xloong",
#  "port": 22,
#  "password": "abc123"
#}
#]
#}'
hosts_info=$(echo ${HOSTS_JSON} | jq -r ".info[]")

for info in "${hosts_info[@]}"; do
  user=$(echo $info | jq -r ".username")
  host=$(echo $info | jq -r ".host")
  port=$(echo $info | jq -r ".port")
  pass=$(echo $info | jq -r ".password")

  script="/home/$user/serv00-play/keepalive.sh"

  output=$(./toserv.sh $user $host $port $pass $script)

  echo "output:$output"

  echo "$output" | while IFS= read -r line; do

  if [[ "$line" == *"RESPONSE:"* ]]; then
    echo "revied.sh: $line"
    msg=$(echo "$line" | sed 's/RESPONSE://g')
    echo "revied.sh:msg:$msg"
    sendmsg="Host:$host, user:$user, $msg"
    if [ $sendtype -eq 1 ]; then
      ./tgsend.sh "$sendmsg"
    elif [ $sendtype -eq 2 ]; then
      ./wxsend.sh "$sendmsg" 
    elif [ $sendtype -eq 3 ]; then
      ./tgsend.sh "$sendmsg"
      ./wxsend.sh "$snedmsg"
    fi
  fi
  done 

done
  

#!/bin/bash

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
#echo "host info:$HOSTS_JSON"
# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))

for info in "${hosts_info[@]}"; do
  user=$(echo $info | jq -r ".username")
  host=$(echo $info | jq -r ".host")
  port=$(echo $info | jq -r ".port")
  pass=$(echo $info | jq -r ".password")

  script="/home/$user/serv00-play/keepalive.sh autoupdate ${SENDTYPE} ${TELEGRAM_TOKEN} ${TELEGRAM_USERID} ${WXSENDKEY} ${BUTTON_URL}"

  output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" "bash -s" <<<"$script")

  echo "output:$output"
  if echo "$output" | grep -q "更新完毕"; then
    echo "登录成功"
  else
    echo "登录失败"
    ./tgsend.sh "Host:$host,user:$user,登录失败请检查!"
  fi
done

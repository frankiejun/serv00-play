#!/bin/bash

installpath="$HOME"
domain=$1
host="$(hostname | cut -d '.' -f 1)"
sno=${host/s/web}
webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
resp=$(devil ssl www add $webIp le le $domain)

if [[ "$resp" =~ .*succesfully.*$ ]]; then
  crontab -l | grep -v "$domain" >tmpcron
  crontab tmpcron
  rm -rf tmpcron
  config="../config.json"
  if [ -e "$config" ]; then
    tg_token=$(jq -r ".telegram_token" "$config")
    tg_userid=$(jq -r ".telegram_userid" "$config")
    if [[ -n "$tg_token" && -n "$tg_userid" ]]; then
      msg="你的域名($domain)申请的SSL证书已下发,请查收!"
      cd $installpath/serv00-play
      ./tgsend.sh "$msg"
    fi
  fi
fi

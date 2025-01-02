#!/bin/bash

installpath="$HOME"
domain=$1
host="$(hostname | cut -d '.' -f 1)"
user=$(whoami)
sno=${host/s/web}
webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
resp=$(devil ssl www add $webIp le le $domain)

cd ${installpath}/serv00-play/ssl

if [[ "$resp" =~ .*succesfully.*$ ]]; then
  crontab -l | grep -v "$domain" >tmpcron
  crontab tmpcron
  rm -rf tmpcron
  config="../config.json"
  if [ -e "$config" ]; then
    TELEGRAM_TOKEN=$(jq -r ".telegram_token" "$config")
    TELEGRAM_USERID=$(jq -r ".telegram_userid" "$config")
    if [[ -n "$TELEGRAM_TOKEN" && -n "$TELEGRAM_USERID" ]]; then
      msg="Host:$host, user:$user, 你的域名($domain)申请的SSL证书已下发,请查收!"
      cd $installpath/serv00-play
      export TELEGRAM_TOKEN="$TELEGRAM_TOKEN" TELEGRAM_USERID="$TELEGRAM_USERID"
      ./tgsend.sh "$msg"
    fi
  fi
fi

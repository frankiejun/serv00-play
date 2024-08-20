#!/bin/bash

installpath="$HOME"
sendtype=$1
export TELEGRAM_TOKEN="$2"
export TELEGRAM_USERID="$3"
export WXSENDKEY="$4"

#返回0表示成功， 1表示失败
#在if条件中，0会执行，1不会执行
checkvlessAlive() {
  if ps aux | grep app.js | grep -v "grep"; then
    return 0
  else
    return 1
  fi
}

checkvmessAlive() {
  local c=0
  if ps aux | grep web.js | grep -v "grep" >/dev/null; then
    c=$((c + 1))
  fi

  if ps aux | grep cloud | grep -v "grep" >/dev/null; then
    c=$((c + 1))
  fi
  if ps aux | grep server.js | grep -v "grep" >/dev/null; then
    c=$((c + 1))
  fi

  echo "c=$c"
  if [ $c -eq 3 ]; then
    return 0
  fi
  return 1 # 有一个或多个进程不在运行

}

#main
cd ${installpath}/serv00-play/
if [ ! -f config.json ]; then
  echo "未配置保活项目，请先行配置!"
  exit 0
fi

monitor=($(jq -r ".item[]" config.json))
if [ -z "$TELEGRAM_TOKEN" ]; then
  TELEGRAM_TOKEN=$(jq -r ".telegram_token" config.json)
fi

if [ -z "$TELEGRAM_USERID" ]; then
  TELEGRAM_USERID=$(jq -r ".telegram_userid" config.json)
fi

if [ -z "$WXSENDKEY" ]; then 
  WXSENDKEY=$(jq -r ".wxsendkey" config.json)
fi

if [ -z "$sendtype" ]; then
  sendtype=$(jq -r ".sendtype" config.json)
fi

for obj in "${monitor[@]}"; do
  if [ "$obj" == "vless" ]; then
    if ! checkvlessAlive; then
      cd ${installpath}/serv00-play/vless
      if ! ./start.sh; then
        msg="vless restarted failure."
      else
        msg="vless restarted successfully."
      fi
    fi
  elif [ "$obj" == "vmess" ]; then
    if ! checkvmessAlive; then
      cd ${installpath}/serv00-play/vmess
      if ! ./start.sh; then
        msg="vmess restarted failure."
      else
        msg="vmess restarted successfully."
      fi
    fi
  else 
    continue
  fi

 	cd $installpath/serv00-play 
  if [ "$sendtype" == "1" ]; then
    ./tgsend.sh "$msg"
  elif [ "$sendtype" == "2" ]; then
    ./wxsend.sh "$msg"
  elif [ "$sendtype" == "3" ]; then
    ./tgsend.sh "$msg"
    ./wxsend.sh "$msg"
  fi

done

#!/bin/bash

installpath="$HOME"
autoUp=$1
sendtype=$2
export TELEGRAM_TOKEN="$3"
export TELEGRAM_USERID="$4"
export WXSENDKEY="$5"

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
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    c=$((c + 1))
  fi

  if ps aux | grep cloudflare | grep -v "grep" >/dev/null; then
    c=$((c + 1))
  fi

  if [ $c -eq 2 ]; then
    return 0
  fi
  return 1 # 有一个或多个进程不在运行

}

checkHy2Alive() {
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    return 0
  else
    return 1
  fi

}

addCron() {
  local tm=$1
  crontab -l | grep -v "keepalive" >mycron
  echo "*/$tm * * * * bash ${installpath}/serv00-play/keepalive.sh > /dev/null 2>&1 " >>mycron
  crontab mycron
  rm mycron

}

sendMsg() {
  local msg=$1
  if [ -n "$msg" ]; then
    cd $installpath/serv00-play
    msg="Host:$host, user:$user, $msg"
    if [ "$sendtype" == "1" ]; then
      ./tgsend.sh "$msg"
    elif [ "$sendtype" == "2" ]; then
      ./wxsend.sh "$msg"
    elif [ "$sendtype" == "3" ]; then
      ./tgsend.sh "$msg"
      ./wxsend.sh "$msg"
    fi
  fi
}

checkResetCron() {
  local msg=""
  cd ${installpath}/serv00-play/
  if ! crontab -l | grep keepalive; then
    msg="crontab记录被删过,并且已重建。"
    tm=$(jq -r ".chktime" config.json)
    addCron "$tm"
    sendMsg $msg
  fi
}

autoUpdate() {
  if [ -d ${installpath}/serv00-play ]; then
    cd ${installpath}/serv00-play/
    git stash
    if git pull; then
      echo "更新完毕"
    fi
    #重新给各个脚本赋权限
    chmod +x ./start.sh
    chmod +x ./keepalive.sh
    chmod +x ${installpath}/serv00-play/vless/start.sh
    chmod +x ${installpath}/serv00-play/singbox/start.sh
    chmod +x ${installpath}/serv00-play/singbox/killsing-box.sh
  fi

}
#main
if [ -n "$autoUp" ]; then
  autoUpdate
fi

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

host=$(hostname)
user=$(whoami)

for obj in "${monitor[@]}"; do
  msg=""
  if [ "$obj" == "vless" ]; then
    if ! checkvlessAlive; then
      cd ${installpath}/serv00-play/vless
      chmod +x ./start.sh && ./start.sh
      sleep 3
      if ! checkvlessAlive; then
        msg="vless restarted failure."
      else
        msg="vless restarted failure."
      fi
    fi
  elif [ "$obj" == "vmess" ]; then
    if ! checkvmessAlive; then
      cd ${installpath}/serv00-play/singbox
      chmod +x ./start.sh && ./start.sh 1 keep
      sleep 3
      if ! checkvmessAlive; then
        msg="vmess restarted failure."
      else
        msg="vmess restarted successfully."
      fi
    fi
    #hy2和vmess+ws都只需要启动serv00sb，所以可以这么写
  elif [ "$obj" == "hy2/vmess+ws" ]; then
    if ! checkHy2Alive; then
      cd ${installpath}/serv00-play/singbox
      chmod +x ./start.sh && ./start.sh 2 keep
      sleep 3
      if ! checkHy2Alive; then
        msg="hy2 restarted failure."
      else
        msg="hy2 restarted successfully."
      fi
    fi
  else
    continue
  fi

  sendMsg "$msg"

done

checkResetCron

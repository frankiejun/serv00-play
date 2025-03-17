#!/bin/bash

installpath="$HOME"
source ${installpath}/serv00-play/utils.sh

LOCKFILE="$installpath/serv00-play/.keepalive.lock"

# 检查是否已经有一个实例在运行
if [ -e "$LOCKFILE" ]; then
  echo "另一个实例正在运行，退出..."
  exit 1
fi

# 创建锁文件
touch "$LOCKFILE"

# 定义清理函数
cleanup() {
  rm -f "$LOCKFILE"
  exit
}

# 捕获脚本退出信号并调用清理函数
trap cleanup INT TERM EXIT

autoUp=$1
sendtype=$2
TELEGRAM_TOKEN="$3"
TELEGRAM_USERID="$4"
WXSENDKEY="$5"
BUTTON_URL="$6"
PASS="$7"
autoUpdateHyIP="$8"

#echo "TELEGRAM_TOKEN=$TELEGRAM_TOKEN, TELEGRAM_USERID=$TELEGRAM_USERID,WXSENDKEY=$WXSENDKEY,BUTTON_URL=$BUTTON_URL,pass=$PASS"

checkHy2Alive() {
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    return 0
  else
    return 1
  fi

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
  echo "run checkResetCron"
  local msg=""
  cd ${installpath}/serv00-play/
  tm=$(jq -r ".chktime" config.json)
  if [ "$tm" == "null" ]; then
    return
  fi
  crontab -l | grep keepalive
  if ! crontab -l | grep keepalive; then
    msg="crontab记录被删过,并且已重建。"
    addCron "$tm"
    sendMsg $msg
  fi
}

#构建消息配置文件
makeMsgConfig() {
  if [ -n "$TELEGRAM_TOKEN" ] || [ -n "$WXSENDKEY" ]; then
    if [[ "$TELEGRAM_TOKEN" != "null" || "$WXSENDKEY" != "null" ]]; then
      cat >msg.json <<EOF
   {
      "telegram_token": "$TELEGRAM_TOKEN",
      "telegram_userid": "$TELEGRAM_USERID",
      "wxsendkey": "$WXSENDKEY",
      "sendtype": "$sendtype",
      "button_url": "$BUTTON_URL",
      "password": "$PASS"
   }
EOF
    fi
  else
    echo "TELEGRAM_TOKEN 和 WXSENDKEY 变量均未设置"
  fi
}

autoUpdate() {
  echo "正在自动更新代码..."
  if [ -d ${installpath}/serv00-play ]; then
    cd ${installpath}/serv00-play/
    git stash
    timeout 15s git pull
    echo "更新完毕"

    #重新给各个脚本赋权限
    chmod +x ./start.sh
    chmod +x ./keepalive.sh
    chmod +x ./tgsend.sh
    chmod +x ./wxsend.sh
    chmod +x ${installpath}/serv00-play/singbox/start.sh
    chmod +x ${installpath}/serv00-play/singbox/killsing-box.sh
    chmod +x ${installpath}/serv00-play/ssl/cronSSL.sh
  fi

}

startNeZhaAgent() {
  local workedir="${installpath}/serv00-play/nezha"
  cd ${workedir}
  local config="nezha.json"
  if [[ ! -e "$config" ]]; then
    red "未安装哪吒探针，请先进行安装！"
    return 1
  fi
  nezha_domain=$(jq -r ".nezha_domain" $config)
  nezha_port=$(jq -r ".nezha_port" $config)
  nezha_pwd=$(jq -r ".nezha_pwd" $config)
  ver=$(jq -r ".version" $config)
  tls=$(jq -r ".tls" $config)

  if checknezhaAgentAlive; then
    stopNeZhaAgent
  fi

  local args="--report-delay 4 --disable-auto-update --disable-force-update "
  if [[ "$tls" == "y" ]]; then
    args="${args} --tls "
  fi

  if [[ "$ver" == "1" ]]; then
    nohup ./nezha-agent ${args} -s "${nezha_domain}:${nezha_port}" -p "${nezha_pwd}" >/dev/null 2>&1 &
  else
    local yamlcfg="config.yaml"
    local datatls=""
    if [[ "$tls" == "y" ]]; then
      datatls="tls: true"
    else
      datatls="tls: false"
    fi
    nohup ./nezha-agent -c $yamlcfg 2>&1 &
  fi

}

startMtg() {
  cd ${installpath}/serv00-play/dmtg

  config="config.json"

  secret=$(jq -r ".secret" $config)
  port=$(jq -r ".port" $config)
  cmd="nohup ./mtg simple-run -n 1.1.1.1 -t 30s -a 1MB 0.0.0.0:$port $secret -c 8192 --prefer-ip=\"prefer-ipv6\" >/dev/null 2>&1 &"
  eval "$cmd"
  sleep 1
  if checkMtgAlive; then
    echo "启动成功"
  else
    echo "启动失败，请检查进程"
  fi

}

startNeZhaDashboard() {
  cd ${installpath}/serv00-play/nezha-board
  if checkProcAlive nezha-dashboard; then
    stopNeZhaDashboard
  fi
  nohup ./nezha-dashboard -c config.yaml >borad.log 2>&1 &
  if checkProcAlive nezha-dashboard; then
    green "面板已启动!"
  else
    red "面板启动失败,请查看日志borad.log"
  fi

}

startAlist() {
  alistpath="${installpath}/serv00-play/alist"

  if [[ -d "$alistpath/data" && -e "$alistpath/alist" ]]; then
    echo "正在启动alist..."
    cd $alistpath
    domain=$(jq -r ".domain" config.json)

    if checkProcAlive "alist"; then
      echo "alist已启动，请勿重复启动!"
    else
      nohup ./alist server >/dev/null 2>&1 &
      sleep 2
      if ! checkProcAlive "alist"; then
        red "启动失败，请检查!"
        return 1
      else
        echo "启动成功!"
      fi
    fi
  else
    red "请先行安装再启动!"
    return
  fi

}

startSunPanel() {
  cd ${installpath}/serv00-play/sunpanel
  cmd="nohup ./sun-panel >/dev/null 2>&1 &"
  eval "$cmd"
}

startWebSSH() {
  cd ${installpath}/serv00-play/webssh
  ssh_port=$(jq -r ".port" config.json)
  cmd="nohup ./wssh --port=$ssh_port  --fbidhttp=False --wpintvl=30 --xheaders=False --encoding='utf-8' --delay=10  >/dev/null 2>&1 &"
  eval "$cmd"
}

#main
host=$(hostname)
user=$(whoami)

echo "正在调用keepalive.sh"
if [[ "$autoUp" == "autoupdate" ]]; then
  echo "run autoUpdate"
  autoUpdate
fi

echo "Host:$host, user:$user"
cd ${installpath}/serv00-play/

if [[ -n "$autoUp" ]]; then
  makeMsgConfig
fi
if [ ! -f config.json ]; then
  echo "未配置保活项目，请先行配置!"
  cleanup
fi

monitor=($(jq -r ".item[]" config.json))

tg_token=$(jq -r ".telegram_token // empty" config.json)

if [[ -z "$tg_token" ]]; then
  echo "从msg.json获取 telegram_token"
  if [[ -e "msg.json" ]]; then
    TELEGRAM_TOKEN=$(jq -r '.telegram_token // empty' msg.json)
  fi
else
  TELEGRAM_TOKEN=$tg_token
fi

tg_userid=$(jq -r ".telegram_userid // empty" config.json)

if [[ -z "$tg_userid" ]]; then
  echo "从msg.json获取telegram_userid"
  if [[ -e "msg.json" ]]; then
    TELEGRAM_USERID=$(jq -r ".telegram_userid // empty" msg.json)
  fi
else
  TELEGRAM_USERID=$tg_userid
fi

wx_sendkey=$(jq -r ".wxsendkey // empty" config.json)

if [[ -z "$wx_sendkey" ]]; then
  echo "从msg.json获取wxsendkey"
  if [[ -e "msg.json" ]]; then
    WXSENDKEY=$(jq -r ".wxsendkey // empty" msg.json)
  fi
else
  WXSENDKEY=$wx_sendkey
fi

send_type=$(jq -r ".sendtype // empty" config.json)
if [ -z "$send_type" ]; then
  echo "从msg.json获取 sendtype"
  if [[ -e "msg.json" ]]; then
    sendtype=$(jq -r ".sendtype // empty" msg.json)
  fi
else
  sendtype=$send_type
fi

if [ -z "$BUTTON_URL" ]; then
  echo "从msg.json获取 button_url"
  if [[ -e "msg.json" ]]; then
    BUTTON_URL=$(jq -r ".button_url // empty" msg.json)
  fi
fi

if [ -z "$PASS" ]; then
  echo "从msg.json获取 password"
  if [[ -e "msg.json" ]]; then
    PASS=$(jq -r ".password // empty" msg.json)
  fi
fi

export TELEGRAM_TOKEN TELEGRAM_USERID WXSENDKEY sendtype BUTTON_URL PASS

#echo "最终TELEGRAM_TOKEN=$TELEGRAM_TOKEN,TELEGRAM_USERID=$TELEGRAM_USERID"

for obj in "${monitor[@]}"; do
  msg=""
  #   echo "obj= $obj"
  if [ "$obj" == "sun-panel" ]; then
    if ! checkProcAlive "sun-panel"; then
      startSunPanel
      sleep 2
      if ! checkProcAlive "sun-panel"; then
        msg="sun-panel 重启失败."
      else
        msg="sun-panel 重启成功."
      fi
    fi
  elif [ "$obj" == "webssh" ]; then
    if ! checkProcAlive "wssh"; then
      startWebSSH
      sleep 2
      if ! checkProcAlive "wssh"; then
        msg="webssh 重启失败."
      else
        msg="webssh 重启成功."
      fi
    fi
  elif [ "$obj" == "vmess" ]; then
    if ! checkvmessAlive; then
      cd ${installpath}/serv00-play/singbox
      chmod +x ./start.sh && ./start.sh 1 keep
      sleep 1
      if ! checkvmessAlive; then
        msg="vmess 重启失败."
      else
        msg="vmess 重启成功."
      fi
    fi
    #hy2和vmess+ws都只需要启动serv00sb，所以可以这么写
  elif [[ "$obj" == "hy2/vmess+ws" || "$obj" == "hy2" ]]; then
    if ! checkHy2Alive; then
      #echo "重启serv00sb中..."
      cd ${installpath}/serv00-play/singbox
      chmod +x ./start.sh && ./start.sh 2 keep
      sleep 1
      if ! checkHy2Alive; then
        msg="hy2 重启失败."
      else
        msg="hy2 重启成功."
      fi
    fi
  elif [ "$obj" == "nezha-agent" ]; then
    if ! checknezhaAgentAlive; then
      cd ${installpath}/serv00-play/nezha
      startNeZhaAgent
      sleep 1
      if ! checknezhaAgentAlive; then
        msg="nezha-agent 重启失败."
      else
        msg="nezha-agent 重启成功."
      fi
    fi
  elif [ "$obj" == "nezha-dashboard" ]; then
    if ! checkProcAlive "nezha-dashboard"; then
      cd ${installpath}/serv00-play/nezha-board
      startNeZhaDashboard
      sleep 1
      if ! checkProcAlive "nezha-dashboard"; then
        msg="nezha-dashboard 重启失败."
      else
        msg="nezha-dashboard 重启成功."
      fi
    fi
  elif [ "$obj" == "mtg" ]; then
    if ! checkMtgAlive; then
      cd ${installpath}/serv00-play/dmtg
      startMtg
      sleep 1
      if ! checkMtgAlive; then
        msg="mtproto 重启失败."
      else
        msg="mtproto 重启成功."
      fi
    fi
  elif [ "$obj" == "alist" ]; then
    if ! checkProcAlive "alist"; then
      startAlist
      sleep 1
      if ! checkProcAlive "alist"; then
        msg="alist 重启失败."
      else
        msg="alist 重启成功."
      fi
    fi
  elif [ "$obj" == "wssh" ]; then
    if ! checkProcAlive wssh; then
      startAlist
      sleep 1
      if ! checkAlistAlive; then
        msg="wssh 重启失败."
      else
        msg="wssh 重启成功."
      fi
    fi
  else
    continue
  fi

  sendMsg "$msg"

done

if [ ${#monitor[@]} -gt 0 ]; then
  checkResetCron
fi

if [[ "$autoUpdateHyIP" == "Y" ]]; then
  echo "正在自动更新HY2IP..."
  cd ${installpath}/serv00-play/singbox
  chmod +x ./autoUpdateHyIP.sh && ./autoUpdateHyIP.sh
fi

devil info account &>/dev/null

# 清理锁文件
cleanup

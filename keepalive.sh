#!/bin/bash

installpath="$HOME"

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
    ((c + 1))
  fi

  if ps aux | grep cloud | grep -v "grep" >/dev/null; then
    ((c + 1))
  fi
  if ps aux | grep server.js | grep -v "grep" >/dev/null; then
    ((c + 1))
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
monitor=$(jq -r ".item[]" config.json)
for obj in "${monitor[@]}"; do
  if [ "$obj" == "vless" ]; then
    if ! checkvlessAlive; then
      cd ${installpath}/serv00-play/vless
      if ! ./start.sh; then
        echo "RESPONSE:vless restarts failure."
      else
        echo "RESPONSE:vless restarts successfully."
      fi
    fi
  elif [ "$obj" == "vmess" ]; then
    if ! checkvmessAlive; then
      cd ${installpath}/serv00-play/vmess
      if ! ./start.sh; then
        echo "vmess restarts failure."
      else
        echo "vmess restarts successfully."
      fi
    fi
  fi
done

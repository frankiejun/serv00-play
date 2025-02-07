#!/bin/bash

installpath="$HOME"
USER="$(whoami)"
if [[ -e "$installpath/serv00-play" ]]; then
  source ${installpath}/serv00-play/utils.sh
fi

cd ${installpath}/serv00-play/singbox
if [[ ! -e "singbox.json" || ! -e "config.json" ]]; then
  red "未安装节点，请先安装!"
  return 1
fi

hy2_ip=$(get_ip)

if [[ -z "$hy2_ip" ]]; then
  red "很遗憾，已无可用IP!"
  return 1
fi
if ! upInsertFd singbox.json HY2IP "$hy2_ip"; then
  red "更新singbox.json配置文件失败!"
  return 1
fi

if ! upSingboxFd config.json "inbounds" "tag" "hysteria-in" "listen" "$hy2_ip"; then
  red "更新config.json配置文件失败!"
  return 1
fi
green "HY2 更换IP成功，当前IP为 $hy2_ip"

echo "正在重启sing-box..."
stop_sing_box
start_sing_box

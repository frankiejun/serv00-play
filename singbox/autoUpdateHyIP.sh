#!/bin/bash

installpath="$HOME"
USER="$(whoami)"
if [[ -e "$installpath/serv00-play" ]]; then
  source ${installpath}/serv00-play/utils.sh
fi

cd ${installpath}/serv00-play/singbox
if [[ ! -e "singbox.json" || ! -e "config.json" ]]; then
  red "未安装节点，请先安装!"
  exit
fi
config="singbox.json"
cur_hy2_ip=$(jq -r ".HY2IP" $config)
# 检查 cur_hy2_ip 是否为空
if [[ -z "$cur_hy2_ip" ]]; then
  red "当前 HY2IP 为空，未安装hy2节点!"
  exit
fi

show_ip_status

if printf '%s\n' "${useIPs[@]}" | grep -q "$cur_hy2_ip"; then
  echo "目前ip可用"
  exit
fi

if [[ ${#useIPs[@]} -eq 0 ]]; then
  red "当前无可用IP!"
  exit
fi

hy2_ip=${useIPs[0]}

if [[ -z "$hy2_ip" ]]; then
  red "很遗憾，已无可用IP!"
  exit
fi

if ! upInsertFd singbox.json HY2IP "$hy2_ip"; then
  red "更新singbox.json配置文件失败!"
  exit
fi

if ! upSingboxFd config.json "inbounds" "tag" "hysteria-in" "listen" "$hy2_ip"; then
  red "更新config.json配置文件失败!"
  exit
fi
green "HY2 更换IP成功，当前IP为 $hy2_ip"

echo "正在重启sing-box..."
stop_sing_box
start_sing_box

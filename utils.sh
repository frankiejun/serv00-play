#!/bin/bash

RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;96m'
WHITE='\033[0;37m'
RESET='\033[0m'
yellow() {
  echo -e "${YELLOW}$1${RESET}"
}
green() {
  echo -e "${GREEN}$1${RESET}"
}
red() {
  echo -e "${RED}$1${RESET}"
}
installpath="$HOME"

checknezhaAgentAlive() {
  if ps aux | grep nezha-agent | grep -v "grep" >/dev/null; then
    return 0
  else
    return 1
  fi
}

checkvmessAlive() {
  local c=0
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    ((c++))
  fi

  if ps aux | grep cloudflared | grep -v "grep" >/dev/null; then
    ((c++))
  fi

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

#返回0表示成功， 1表示失败
#在if条件中，0会执行，1不会执行
checkProcAlive() {
  local procname=$1
  if ps aux | grep "$procname" | grep -v "grep" >/dev/null; then
    return 0
  else
    return 1
  fi
}

stopProc() {
  local procname=$1
  r=$(ps aux | grep "$procname" | grep -v "grep" | awk '{print $2}')
  if [ -z "$r" ]; then
    return 0
  else
    kill -9 $r
  fi
  echo "已停掉$procname!"
}

checkSingboxAlive() {
  local c=0
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    ((c++))
  fi

  if ps aux | grep cloudflare | grep -v "grep" >/dev/null; then
    ((c++))
  fi

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

checkMtgAlive() {
  if ps aux | grep mtg | grep -v "grep" >/dev/null; then
    return 0
  else
    return 1
  fi
}

stopNeZhaAgent() {
  r=$(ps aux | grep nezha-agent | grep -v "grep" | awk '{print $2}')
  if [ -z "$r" ]; then
    return 0
  else
    kill -9 $r
  fi
  echo "已停掉nezha-agent!"
}

writeWX() {
  has_fd=$(echo "$config_content" | jq 'has("wxsendkey")')
  if [ "$has_fd" == "true" ]; then
    wx_sendkey=$(echo "$config_content" | jq -r ".wxsendkey")
    read -p "已有 WXSENDKEY ($wx_sendkey), 是否修改? [y/n] [n]:" input
    input=${input:-n}
    if [ "$input" == "y" ]; then
      read -p "请输入 WXSENDKEY:" wx_sendkey
    fi
    json_content+="  \"wxsendkey\": \"${wx_sendkey}\", \n"
  else
    read -p "请输入 WXSENDKEY:" wx_sendkey
    json_content+="  \"wxsendkey\": \"${wx_sendkey}\", \n"
  fi

}

writeTG() {
  has_fd=$(echo "$config_content" | jq 'has("telegram_token")')
  if [ "$has_fd" == "true" ]; then
    tg_token=$(echo "$config_content" | jq -r ".telegram_token")
    read -p "已有 TELEGRAM_TOKEN ($tg_token), 是否修改? [y/n] [n]:" input
    input=${input:-n}
    if [ "$input" == "y" ]; then
      read -p "请输入 TELEGRAM_TOKEN:" tg_token
    fi
    json_content+="  \"telegram_token\": \"${tg_token}\", \n"
  else
    read -p "请输入 TELEGRAM_TOKEN:" tg_token
    json_content+="  \"telegram_token\": \"${tg_token}\", \n"
  fi

  has_fd=$(echo "$config_content" | jq 'has("telegram_userid")')
  if [ "$has_fd" == "true" ]; then
    tg_userid=$(echo "$config_content" | jq -r ".telegram_userid")
    read -p "已有 TELEGRAM_USERID ($tg_userid), 是否修改? [y/n] [n]:" input
    input=${input:-n}
    if [ "$input" == "y" ]; then
      read -p "请输入 TELEGRAM_USERID:" tg_userid
    fi
    json_content+="  \"telegram_userid\": \"${tg_userid}\", \n"
  else
    read -p "请输入 TELEGRAM_USERID:" tg_userid
    json_content+="  \"telegram_userid\": \"${tg_userid}\",\n"
  fi
}

cleanCron() {
  echo "" >null
  crontab null
  rm null
}

delCron() {
  crontab -l | grep -v "keepalive" >mycron
  crontab mycron >/dev/null 2>&1
  rm mycron
}

addCron() {
  local tm=$1
  crontab -l | grep -v "keepalive" >mycron
  echo "*/$tm * * * * bash ${installpath}/serv00-play/keepalive.sh > /dev/null 2>&1 " >>mycron
  crontab mycron >/dev/null 2>&1
  rm mycron

}

get_webip() {
  # 获取主机名称，例如：s2.serv00.com
  local hostname=$(hostname)

  # 提取主机名称中的数字，例如：2
  local host_number=$(echo "$hostname" | awk -F'[s.]' '{print $2}')

  # 构造主机名称的数组
  local hosts=("web${host_number}.serv00.com" "cache${host_number}.serv00.com")

  # 初始化最终 IP 变量
  local final_ip=""

  # 遍历主机名称数组
  for host in "${hosts[@]}"; do
    # 获取 API 返回的数据
    local response=$(curl -s "https://ss.botai.us.kg/api/getip?host=$host")

    # 检查返回的结果是否包含 "not found"
    if [[ "$response" =~ "not found" ]]; then
      continue
    fi

    # 提取第一个字段作为 IP，并检查第二个字段是否为 "Accessible"
    local ip=$(echo "$response" | awk -F "|" '{ if ($2 == "Accessible") print $1 }')
    # webxx.serv00.com域名对应的ip作为兜底ip
    if [[ "$host" == "web${host_number}.serv00.com" ]]; then
      final_ip=$(echo "$response" | awk -F "|" '{print $1}')
    fi

    # 如果找到了 "Accessible"，返回 IP
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return
    fi
  done

  echo "$final_ip"
}

get_ip() {
  # 获取主机名称，例如：s2.serv00.com
  local hostname=$(hostname)

  # 提取主机名称中的数字，例如：2
  local host_number=$(echo "$hostname" | awk -F'[s.]' '{print $2}')

  # 构造主机名称的数组
  local hosts=("cache${host_number}.serv00.com" "web${host_number}.serv00.com" "$hostname")

  # 初始化最终 IP 变量
  local final_ip=""

  # 遍历主机名称数组
  for host in "${hosts[@]}"; do
    # 获取 API 返回的数据
    local response=$(curl -s "https://ss.botai.us.kg/api/getip?host=$host")

    # 检查返回的结果是否包含 "not found"
    if [[ "$response" =~ "not found" ]]; then
      continue
    fi

    # 提取第一个字段作为 IP，并检查第二个字段是否为 "Accessible"
    local ip=$(echo "$response" | awk -F "|" '{ if ($2 == "Accessible") print $1 }')

    # 如果找到了 "Accessible"，返回 IP
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return
    fi

    final_ip=$ip
  done

  echo "$final_ip"
}

isServ00() {
  [[ $(hostname) == *"serv00"* ]]
}

#获取端口
getPort() {
  local type=$1
  local opts=$2

  local key="$type|$opts"
  #echo "key: $key"
  #port list中查找，如果没有随机分配一个
  if [[ -n "${port_array["$key"]}" ]]; then
    #echo "找到list中的port"
    echo "${port_array["$key"]}"
  else
    # echo "devil port add $type random $opts"
    rt=$(devil port add $type random $opts)
    if [[ "$rt" =~ .*succesfully.*$ || "$rt" =~ .*Ok.*$ ]]; then
      loadPort
      if [[ -n "$port_array["$key"]" ]]; then
        echo "${port_array["$key"]}"
      else
        echo "failed"
      fi
    else
      echo "failed"
    fi
  fi
}

randomPort() {
  local type=$1
  local opts=$2
  port=""
  #echo "type:$type, opts:$opts"
  read -p "是否自动分配${opts}端口($type)？[y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" == "y" ]]; then
    port=$(getPort $type $opts)
    if [[ "$port" == "failed" ]]; then
      read -p "自动分配端口失败，请手动输入${opts}端口:" port
    else
      green "自动分配${opts}端口为:${port}"
    fi
  else
    read -p "请输入${opts}端口($type):" port
  fi
}

declare -A port_array
#检查是否可以自动分配端口
loadPort() {
  output=$(devil port list)

  port_array=()
  # 解析输出内容
  index=0
  while read -r port typ opis; do
    # 跳过标题行
    if [[ "$port" =~ "Port" ]]; then
      continue
    fi
    #echo "port:$port,typ:$typ, opis:$opis"
    if [[ "$port" =~ "Brak" || "$port" == "No" ]]; then
      echo "未分配端口"
      return 0
    fi
    # 将 Typ 和 Opis 合并并存储到数组中
    if [[ -n "$typ" ]]; then
      # 如果 Opis 为空则用空字符串代替
      opis=${opis:-""}
      combined="${typ}|${opis}"
      port_array["$combined"]="$port"
      # echo "port_array 读入 key=$combined, value=$port"
      ((index++))
    fi
  done <<<"$output"

  return 0
}

cleanPort() {
  output=$(devil port list)
  while read -r port typ opis; do
    # 跳过标题行
    if [[ "$typ" == "Type" ]]; then
      continue
    fi
    if [[ "$port" == "Brak" || "$port" == "No" ]]; then
      return 0
    fi
    if [[ -n "$typ" ]]; then
      devil port del $typ $port >/dev/null 2>&1
    fi
  done <<<"$output"
  return 0
}

checkDownload() {
  local file=$1
  local filegz="$file.gz"
  local is_dir=${2:-0}

  if [[ $is_dir -eq 1 ]]; then
    filegz="$file.tar.gz"
  fi

  #检查并下载核心程序
  if [[ ! -e $file ]] || [[ $(file $file) == *"text"* ]]; then
    echo "正在下载 $file..."
    url="https://gfg.fkj.pp.ua/app/serv00/$filegz?pwd=fkjyyds666"
    curl -L -sS --max-time 20 -o $filegz "$url"

    if file $filegz | grep -q "text"; then
      echo "无法正确下载!!!"
      rm -f $filegz
      return 1
    fi
    if [ -e $filegz ]; then
      if [[ $is_dir -eq 1 ]]; then
        tar -zxf $filegz
      else
        gzip -d $filegz
      fi
    else
      echo "下载失败，可能是网络问题."
      return 1
    fi
    #下载失败
    if [[ $is_dir -eq 0 && ! -e $file ]]; then
      echo "无法下载核心程序，可能网络问题，请检查！"
      return 1
    fi
    # 设置可执行权限
    if [[ $is_dir -eq 0 ]]; then
      chmod +x "$file"
    fi
    echo "下载完毕!"
  fi
  return 0
}

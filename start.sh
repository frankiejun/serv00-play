#!/bin/bash


RED='\033[0;91m'
GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;96m'
WHITE='\033[0;37m'
RESET='\033[0m'
yellow(){
  echo -e "${YELLOW} $1 ${RESET}"
}
green(){
  echo -e "${GREEN} $1 ${RESET}"
}
red(){
  echo -e "${RED} $1 ${RESET}"
}
installpath="$HOME"


PS3="请选择(输入0退出): "
install(){
  cd
  if [ -d serv00-play ]; then
    cd "serv00-play"
    git stash
    if git pull; then
      echo "更新完毕"
     #重新给各个脚本赋权限
      chmod +x ./start.sh
      chmod +x ./keepalive.sh
      chmod +x ${installpath}/serv00-play/vless/start.sh
      chmod +x ${installpath}/serv00-play/singbox/start.sh
      chmod +x ${installpath}/serv00-play/singbox/killsing-box.sh
      return
    fi
  fi

  echo "正在安装..."
  if ! git clone https://github.com/frankiejun/serv00-play.git; then
    echo -e "${RED}安装失败!${RESET}"
    exit 1;
  fi
  echo -e "${YELLOW}安装成功${RESET}"
}

checkvlessAlive(){
  if  ps  aux | grep app.js | grep -v "grep" > /dev/null ; then
    return 0
  else
    return 1
  fi  
}

checknezhaAgentAlive(){
   if ps aux | grep nezha-agent | grep -v "grep" >/dev/null ; then
      return 0
   else
      return 1
   fi
}

checkvmessAlive(){
  local c=0
  if ps  aux | grep web.js | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi

  if ps aux | grep cloud | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi  

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

checkSingboxAlive(){
  local c=0
  if ps  aux | grep serv00sb | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi

  if ps aux | grep cloudflare | grep -v "grep" > /dev/null ; then
    ((c+1))
  fi  

  if [ $c -eq 2 ]; then
    return 0
  fi

  return 1 # 有一个或多个进程不在运行

}

checkMtgAlive(){
   if ps aux | grep mtg | grep -v "grep" >/dev/null ; then
      return 0
   else
      return 1
   fi
}

stopNeZhaAgent(){
  r=$(ps aux | grep nezha-agent | grep -v "grep" | awk '{print $2}' )
  if [ -z "$r" ]; then
    return 0
  else  
    kill -9 $r
  fi
  echo "已停掉nezha-agent!"
}


startVless(){
  cd ${installpath}/serv00-play/vless
  
  if checkvlessAlive; then
    echo -e "${RED}vless 已在运行，请勿重复操作!${RESET}"
    exit 1
  fi

  if ! ./start.sh; then
    echo e "${RED}vless启动失败！${RESET}"
    exit 1
  fi

  echo -e "${YELLOW}启动成功!${RESET}"

}

startVmess(){
  cd ${installpath}/serv00-play/vmess
  
  if checkvmessAlive; then
    echo -e "$RED}vmess 已在运行，请勿重复操作!${RESET}"
    exit 1
  else
    chmod 755 ./killvmess.sh
    ./killvmess.sh
  fi

  if ! ./start.sh; then
    echo "vmess启动失败！"
    exit 1
  fi

  echo -e "${YELLOW}启动成功!${RESET}"

}

stopVless(){
  r=$(ps aux | grep app.js | grep -v "grep" | awk '{print $2}' )
  if [ -z "$r" ]; then
    echo "没有运行!"
    return
  else  
    kill -9 $r
  fi
  echo "已停掉vless!"
}

stopVmess(){
  cd ${installpath}/serv00-play/vmess
  if [ -f killvmess.sh ]; then
    chmod 755 ./killvmess.sh
    ./killvmess.sh
  else
    echo "请先安装serv00-play!!!"
    return
  fi
  echo "已停掉vmess!"
}

createVlesConfig(){
      read -p "请输入PORT:" port

      cat > vless.json <<EOF
      {
        "UUID":"$(uuidgen -r)",
        "PORT":$port

      }
EOF
}

configVless(){
  cd ${installpath}/serv00-play/vless
  
  if [ -f "vless.json" ]; then
    echo "配置文件内容:"
     cat vless.json
    read -p "配置文件已存在，是否还要重新配置? (y/n) [y]:" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    else
     createVlesConfig
    fi
  else
     createVlesConfig
  fi
    echo -e "${YELLOW} vless配置完毕! ${RESET}"
  
}

createVmesConfig(){
   read -p "请输入vmess代理端口:" vmport
  # read -p "请输入uuid:" uuid
   read -p "请输入WSPATH,默认是[serv00]" wspath
   wspath=${wspath:-serv00}

   read -p "请输入ARGO隧道token，如果没有按回车跳过:" token
   read -p "请输入ARGO隧道的域名，如果没有按回车跳过:" domain

  cat > vmess.json <<EOF
  {
     "VMPORT": $vmport,
     "UUID": "$(uuidgen -r)",
     "WSPATH": "$wspath",
     "ARGO_AUTH": "${token:-null}",
     "ARGO_DOMAIN": "${domain:-null}"
  }

EOF
   echo -e "${YELLOW} vmess配置完毕! ${RESET}"
}

configVmess(){
  cd ${installpath}/serv00-play/vmess

  if [ -f ./vmess.json ]; then
    echo "配置文件内容:"
    cat ./vmess.json
    read -p "配置文件已存在，是否还要重新配置? (y/n) [y]:" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    else
     createVmesConfig
    fi
  else
     createVmesConfig
  fi

}

showVlessInfo(){
  user=$(whoami)
  domain=${user}".serv00.net"
  
  cd ${installpath}/serv00-play/vless
  if [ ! -f vless.json ]; then
    echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
    return
  fi
  uuid=$(jq -r ".UUID" vless.json)
  port=$(jq -r ".PORT" vless.json)
  url="vless://${uuid}@${domain}:${port}?encryption=none&security=none&sni=${domain}&allowInsecure=1&type=ws&host=${domain}&path=%2F#serv00-vless"
  echo "v2ray:"
  echo -e "${GREEN}   $url ${RESET}"
}

showVmessInfo(){
  cd ${installpath}/serv00-play/vmess

  if [ ! -f vmess.json ]; then
      echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
      return
  fi
  chmod +x ./list.sh && ./list.sh
}


showSingBoxInfo(){
  cd ${installpath}/serv00-play/singbox
  
  if [ ! -f singbox.json ]; then
      red "配置文件不存在，请先行配置!"
      return
  fi
  if [ ! -e list ]; then
     red "请先运行sing-box"
  fi
  config="singbox.json"
  type=$(jq -r ".TYPE" $config)
  chmod +x ./start.sh && ./start.sh $type list

}

writeWX(){
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

writeTG(){
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

chooseSingbox(){
   echo "保活sing-box中哪个项目: "
   echo " 1.hy2/vmess+ws/socks5 "
   echo " 2.argo+vmess "
   echo " 3.all "
   read -p "请选择:" input
  
  if [ "$input" = "1" ]; then
     item+=("hy2/vmess+ws")
  elif [ "$input" = "2" ]; then
      item+=("vmess")
  elif [ "$input" = "3" ]; then
  item+=("hy2/vmess+ws")
  item+=("vmess")
  else 
      red "无效选择!"
      return 1
 fi

}

setConfig(){
  cd ${installpath}/serv00-play/

  if [ -f config.json ]; then
    echo "目前已有配置:"
    config_content=$(cat config.json)
    echo $config_content
    read -p "是否修改? [y/n] [y]:" input
    input=${input:-y}
    if [ "$input" != "y" ]; then
      return
    fi
  fi
  createConfigFile
}

createConfigFile(){
  
  echo "选择你要保活的项目（可多选，用空格分隔）:"
  echo "1. vless "
  echo "2. sing-box(包含hy2，vmess，socks5) "
  echo "3. 哪吒探针 "
  echo "4. mtproto代理"
  echo "5. alist"
  echo "6. 暂停所有保活功能"
  echo "7. 复通所有保活功能(之前有配置的情况下)"
  item=()

  read -p "请选择: " choices
  choices=($choices)  

  if [[ "${choices[@]}" =~ "6" && ${#choices[@]} -gt 1 ]]; then
     red "选择出现了矛盾项，请重新选择!"
     return 1
  fi

  #过滤重复
  choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

  # 根据选择来询问对应的配置
  for choice in "${choices[@]}"; do
    case "$choice" in
    1) 
       item+=("vless")
       ;;
    2)
      if ! chooseSingbox; then
      return 
      fi
      ;;
    3) 
      item+=("nezha-agent")
       ;;
    4)
      item+=("mtg")
      ;;
    5)
      item+=("alist")
      ;;
    6)
       delCron
       green "设置完毕!"
       return 0
       ;;
    7)
       if [[ ! -e config.json ]]; then
          red "之前未有配置，未能复通!"
          return 1
       fi
       tm=$(jq -r ".chktime" config.json)
       addCron $tm
       green "设置完毕!"
       return 0
       ;;
    *)
       echo "无效选择"
       return 1
       ;;
   esac
done

  json_content="{\n"
  json_content+="   \"item\": [\n"
  
  for item in "${item[@]}"; do
      json_content+="      \"$item\","
  done

  # 删除最后一个逗号并换行
  json_content="${json_content%,}\n"
  json_content+="   ],\n"

  if [ "$num" = "4" ]; then
    json_content+="   \"chktime\": \"null\""
    json_content+="}\n"
    printf "$json_content" > ./config.json
    echo -e "${YELLOW} 设置完成! ${RESET} "
    delCron
    return
  fi

  read -p "配置保活检查的时间间隔(单位分钟，默认5分钟):" tm
  tm=${tm:-"5"}

  json_content+="   \"chktime\": \"$tm\","

  read -p "是否需要配置消息推送? [y/n] [n]:" input
  input=${input:-n}

  if [ "${input}" == "y" ]; then
    json_content+="\n"

    echo "选择要推送的app:"
    echo "1) Telegram "
    echo "2) 微信 "
    echo "3) 以上皆是"

    read -p "请选择:" sendtype
    
    if [ "$sendtype" == "1" ]; then
      writeTG
   elif [ "$sendtype" == "2" ]; then
      writeWX
   elif [ "$sendtype" == "3" ]; then
      writeTG
      writeWX
   else
    echo "无效选择"
    return
   fi
  else 
    sendtype=${sendtype:-"null"}
 fi
  json_content+="\n \"sendtype\": $sendtype \n"
  json_content+="}\n"
  
  # 使用 printf 生成文件
  printf "$json_content" > ./config.json
  addCron $tm
  chmod +x ${installpath}/serv00-play/keepalive.sh
  echo -e "${YELLOW} 设置完成! ${RESET} "

}

cleanCron(){
  echo "" > null
  crontab null
  rm null
}

delCron(){
    crontab -l | grep -v "keepalive" > mycron
    crontab mycron
    rm mycron
}

addCron(){
  local tm=$1
  crontab -l | grep -v "keepalive" > mycron
  echo "*/$tm * * * * bash ${installpath}/serv00-play/keepalive.sh > /dev/null 2>&1 " >> mycron
  crontab mycron
  rm mycron

}



make_vmess_config() {
  cat >tempvmess.json <<EOF
  {
      "tag": "vmess-ws-in",
      "type": "vmess",
      "listen": "::",
      "listen_port": $vmport,
      "users": [
      {
        "uuid": "$uuid"
      }
    ],
    "transport": {
      "type": "ws",
      "path": "/$wspath",
      "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
EOF
}

make_hy2_config() {
  cat > temphy2.json <<EOF
   {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "::",
       "listen_port": $hy2_port,
       "users": [
         {
             "password": "$uuid"
         }
     ],
     "masquerade": "https://www.bing.com",
     "tls": {
         "enabled": true,
         "alpn": [
             "h3"
         ],
         "certificate_path": "cert.pem",
         "key_path": "private.key"
        }
    }
EOF
}

make_socks5_config(){
  cat > tmpsocks5.json <<EOF
  {
      "type": "socks",
      "tag": "socks-in",

       "listen": "::",
       "listen_port": $socks5_port,

        "users": [
        {
          "username": "$username",
          "password": "$password"
        }
        ]
    }
EOF
}

generate_config() {
   comma=""
   comma0=""
  if [[ ! -e "private.key" || ! -e "cert.pem" ]]; then
    openssl ecparam -genkey -name prime256v1 -out "private.key"
    openssl req -new -x509 -days 3650 -key "private.key" -out "cert.pem" -subj "/CN=www.bing.com"
  fi
  if [[ "$type" == "1.1" || "$type" == "1.2" ]]; then
    make_vmess_config
  elif [ "$type" = "2" ]; then
    make_hy2_config
  elif [ "$type" = "1.3" ]; then
    make_socks5_config
  elif [[ "$type" =~ ^(2.4|2.5)$ ]]; then
    make_vmess_config
    comma0=","
    make_socks5_config
  elif [[ "$type" =~ ^(3.1|3.2)$ ]]; then
    make_vmess_config
    comma=","
    make_hy2_config
  elif [[ "$type" == "3.3" ]]; then
    make_hy2_config
    make_socks5_config
    comma0=","
  else
    make_socks5_config
    make_vmess_config
    make_hy2_config
    comma=","
    comma0=","
  fi

  cat >config.json <<EOF
 {
  "log": {
    "disabled": true,
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "google",
        "address": "tls://8.8.8.8",
        "strategy": "ipv4_only",
        "detour": "direct"
      }
    ],
    "rules": [
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "server": "block"
      }
    ],
    "final": "google",
    "strategy": "",
    "disable_cache": false,
    "disable_expire": false
  },
    "inbounds": [
    $([[ "$type" =~ ^(1.3|3.3|2.4|2.5|3.3|4.4|4.5)$ ]] && cat tmpsocks5.json)
    $comma0
    $([[ "$type" == "1.1" || "$type" == "1.2" || "$type" =~ ^(2.4|2.5|3.1|3.2|4.4|4.5)$  ]] && cat tempvmess.json)
    $comma
    $([[ "$type" == "2" || "$type" =~ ^(3|4)\.[0-9]+$ ]] && cat temphy2.json)
   ],
    "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    },
    {
      "type": "block",
      "tag": "block"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "outbound": "dns-out"
      },
      { 
        "ip_is_private": true,
        "outbound": "direct"
      },
      {
        "rule_set": [
          "geosite-category-ads-all"
        ],
        "outbound": "block"
      }
    ],
    "rule_set": [
      {
        "tag": "geosite-category-ads-all",
        "type": "remote",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs",
        "download_detour": "direct"
      }
    ],
    "final": "direct"
   }
}
EOF
rm -rf tempvmess.json temphy2.json tmpsocks5.json
}

isServ00(){
    [[ $(hostname) == *"serv00"* ]]
}

#获取端口
getPort(){
  local type=$1
  local opts=$2

  local key="$type|$opts"
  #echo "key: $key"
  #port list中查找，如果没有随机分配一个
  if [[ -n "${port_array["$key"]}" ]]; then
    # echo "找到list中的port"
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

randomPort(){
    local type=$1
    local opts=$2
    port=""
    #echo "type:$type, opts:$opts"
    read -p "是否自动分配${opts}端口($type)？[y/n] [y]:" input
    input=${input:-y}
    if [[ "$input" == "y" ]]; then
        port=$(getPort $type $opts )
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
loadPort(){
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
  done <<< "$output"

  return 0
}

cleanPort(){
  output=$(devil port list)
  while read -r port typ opis; do
      # 跳过标题行
      if [[ "$typ" == "Type" ]]; then
          continue
      fi
      if [[ "$port" == "Brak" || "$port" == "No"  ]]; then
          return 0
      fi
      if [[ -n "$typ" ]]; then
         devil port del $typ $port  > /dev/null 2>&1
      fi
  done <<< "$output"
  return 0
}

configSingBox(){
  cd ${installpath}/serv00-play/singbox

  loadPort
  if [ -e singbox.json ]; then
    red "目前已有配置如下:"
    cat singbox.json
    read -p "$(echo -e "${RED}继续配置将会覆盖原有配置:[y/n] [n]${RESET}") " input
    input=${input:-n}
    if [ "$input" != "y" ]; then
       return 1
    fi
  fi
  echo "选择你要配置的项目（可多选，用空格分隔）:"
  echo "1. vmess"
  echo "2. hy2"
  echo "3. socks5"
  echo "4. all"

  read -p "请选择: " choices
  choices=($choices)  

  if [[ "${choices[@]}" =~ "4" ]]; then
    choices=("4")
  fi

  #过滤重复
  choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
  type="0"
  # 根据选择来询问对应的配置
  for choice in "${choices[@]}"; do
    case "$choice" in
      1)
        echo "请选择协议(2选1):"
        echo "1. argo+vmess"
        echo "2. vmess+ws "
        read -p "请选择:" co
        
        if [[ "$co" != "1" && "$co" != "2" ]]; then 
          echo "无效输入!"
          return 1
        fi
        
        if [[ "$co" == "1" ]]; then
          type=$(echo "$type + 1.1" | bc)
           randomPort tcp vmess
           if [[ -n "$port" ]]; then
              vmport="$port"
           fi
          read -p "请输入WSPATH,默认是[serv00]: " wspath
          read -p "请输入ARGO隧道token: " token
          read -p "请输入ARGO隧道的域名: " domain
        else
          type=$(echo "$type + 1.2" | bc)
           randomPort tcp vmess
           if [[ -n "$port" ]]; then
              vmport="$port"
           else
              red "未输入端口号"
              return 1
           fi
          read -p "请输入WSPATH,默认是[serv00]: " wspath
          read -p "请输入优选域名:"  goodDomain
        fi
        ;;
      2)
        type=$(echo "$type + 2" | bc)
        randomPort udp hy2
        if [[ -n "$port" ]]; then
          hy2_port="$port"
        else
          red "未输入端口号"
          return 1
        fi
        ;;
      3)
         type=$(echo "$type + 1.3" | bc)
         randomPort tcp socks5
          if [[ -n "$port" ]]; then
          socks5_port="$port"
        else
          red "未输入端口号"
          return 1
        fi
        read -p "请输入socks5用户名:" username
        read -p "请输入socks5密码:" password
        ;;
      4)
        echo "请选择协议(2选1):"
        echo "1. argo+vmess"
        echo "2. vmess+ws "
        read -p "请选择:" co
        
        if [[ "$co" != "1" && "$co" != "2" ]]; then 
          echo "无效输入!"
          return 1
        fi
        
        if [[ "$co" == "1" ]]; then
          type="3.1"
           randomPort tcp vmess
           if [[ -n "$port" ]]; then
              vmport="$port"
          else
              red "未输入端口号"
              return 1
          fi
          read -p "请输入WSPATH,默认是[serv00]: " wspath
          read -p "请输入ARGO隧道token: " token
          read -p "请输入ARGO隧道的域名: " domain
        else
          type="3.2"
           randomPort tcp vmess
           if [[ -n "$port" ]]; then
              vmport="$port"
          else
              red "未输入端口号"
              return 1
          fi
          read -p "请输入WSPATH,默认是[serv00]: " wspath
          read -p "请输入优选域名:"  goodDomain
        fi
        # 配置 hy2
        randomPort udp hy2
        if [[ -n "$port" ]]; then
          hy2_port="$port"
        else
           red "未输入端口号"
           return 1
        fi
        #配置socks5
        type=$(echo "$type + 1.3" | bc)
        randomPort tcp socks5
        if [[ -n "$port" ]]; then
          socks5_port="$port"
        else
          red "未输入端口号"
          return 1
        fi
        read -p "请输入socks5用户名:" username
        read -p "请输入socks5密码:" password
        ;;
      *)
        echo "无效的选择: $choice"
        ;;
    esac
 done

  
  if [[ "$type" != "1.3" ]]; then
    wspath=${wspath:-serv00}
    read -p "是否自动分配UUID? [y/n] [y]:" input
    input=${input:-y}
    if [[ "$input" == "y" ]]; then
      uuid=$(uuidgen -r)
    else
      read -p "请输入UUID:" uuid
    fi
  fi

   cat > singbox.json <<EOF
  {
     "TYPE": "$type",
     "VMPORT": ${vmport:-null},
     "HY2PORT": ${hy2_port:-null},
     "UUID": "$uuid",
     "WSPATH": "${wspath}",
     "ARGO_AUTH": "${token:-null}",
     "ARGO_DOMAIN": "${domain:-null}",
     "GOOD_DOMAIN": "${goodDomain:-null}",
     "SOCKS5_PORT": "${socks5_port:-null}",
     "SOCKS5_USER": "${username:-null}",
     "SOCKS5_PASS": "${password:-null}"
  }

EOF

    generate_config
    yellow "sing-box配置完毕!"  

}

checkDownload(){
  local file=$1
  local filegz="$file.gz"
    #检查并下载核心程序
  if [[ ! -e $file ]] || [[ $(file $file) == *"text"* ]]; then
    echo "正在下载 $file..."
    url="https://gfg.fkj.pp.ua/app/serv00/$filegz?pwd=$password"
    curl -L -sS --max-time 20 -o $filegz "$url"

    if file $filegz | grep "text" ; then
        echo "使用密码不正确!!!"
        rm -f $filegz
        return 1
    fi
    if [ -e $filegz ];  then
       gzip -d $filegz
    else 
       echo "下载失败，可能是网络问题."
       return 1
    fi
    #下载失败
    if [ ! -e $file ]; then
       echo "无法下载核心程序，可能使用密码不对或者网络问题，请检查！"
       return  1
    fi
    chmod +x $file
    echo "下载完毕!"
  fi
  return 0
}

startSingBox(){

  cd ${installpath}/serv00-play/singbox

  
  if [[ ! -e ${installpath}/serv00-play/singbox/serv00sb ]] || [[ ! -e ${installpath}/serv00-play/singbox/cloudflared ]]; then
    read -p "请输入使用密码:" password
  fi
  
  if ! checkDownload "serv00sb"; then
     return 
  fi
  if ! checkDownload "cloudflared"; then
     return 
  fi
  
  if checkSingboxAlive; then
    red "sing-box 已在运行，请勿重复操作!"
    exit 1
  else
    chmod 755 ./killsing-box.sh
    ./killsing-box.sh
  fi

  if chmod +x start.sh && ! ./start.sh; then
    red "sing-box启动失败！"
    exit 1
  fi

  yellow "启动成功!"

}


stopSingBox(){
  cd ${installpath}/serv00-play/singbox
  if [ -f killsing-box.sh ]; then
    chmod 755 ./killsing-box.sh
    ./killsing-box.sh
  else
    echo "请先安装serv00-play!!!"
    return
  fi
  echo "已停掉sing-box!"
}

killUserProc(){
  local user=$(whoami)
  pkill -kill -u $user
}

ImageRecovery(){
  cd ${installpath}/backups/local
  # 定义一个关联数组
  declare -A snapshot_paths

  # 遍历每个符号链接，并将文件夹名称及真实路径保存到数组中
  while read -r line; do
    # 提取文件夹名称和对应的真实路径
    folder=$(echo "$line" | awk '{print $9}')
    real_path=$(echo "$line" | awk '{print $11}')
    
    # 将文件夹名称和真实路径存入数组
    snapshot_paths["$folder"]="$real_path"
  done < <(ls -trl | grep -F "lrwxr")

  size=${#snapshot_paths[@]}
  sorted_keys=($(echo "${!snapshot_paths[@]}" | tr ' ' '\n' | sort -r))
  if [ $size -eq 0 ]; then
    echo "未有备份快照!"
    return   
  fi
  echo  "选择你需要恢复的内容:"
  echo "1. 完整快照恢复 "
  echo "2. 恢复某个文件或目录"
  read -p "请选择:" input


  if [ "$input" = "1" ]; then
      local i=1
      declare -a folders
      for folder in "${sorted_keys[@]}"; do
        echo "${i}. ${folder} "
        i=$((i+1))
      done
      retries=3
      while [ $retries -gt 0 ]; do
        read -p  "请选择恢复到哪一天(序号)？" input
         # 检查输入是否有效
         if [[ $input =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ] && [ "$input" -le $size ]; then
          # 输入有效，退出循环
           targetFolder="${sorted_keys[@]:$input-1:1}"
           echo "你选择的恢复日期是：${targetFolder}"
           break
         else
           # 输入无效，减少重试次数
            retries=$((retries-1))
            echo "输入有误，请重新输入！你还有 $retries 次机会。"
         fi
         if [ $retries -eq 0 ]; then
           echo "输入错误次数过多，操作已取消。"
           return  
         fi
      done
      killUserProc
      srcpath=${snapshot_paths["${targetFolder}"]}
      #echo "srcpath:$srcpath"
       rm -rf ~/* > /dev/null 2>&1  
       rsync -a $srcpath/ ~/  2>/dev/null  
      yellow "快照恢复完成!"
      return
  elif [ "$input" = "2" ]; then
      declare -A foundArr
      read -p "输入你要恢复到文件或目录:" infile
      
      for folder in "${!snapshot_paths[@]}"; do
          path="${snapshot_paths[$folder]}"
         results=$(find "${path}" -name "$infile" 2>/dev/null)
        # echo "111results:|$results|"     
         if [[ -n "$results" ]]; then
          #echo "put |$results| to folder:$folder"
          foundArr["$folder"]="$results"
         fi
      done
      local i=1
      sortedFoundArr=($(echo "${!foundArr[@]}" | tr ' ' '\n' | sort -r))
      declare -A indexPathArr
      for folder in "${sortedFoundArr[@]}"; do
        echo "$i. $folder:"
        results="${foundArr[${folder}]}"
        IFS=$'\n' read -r -d '' -a paths <<< "$results"
        local j=1
        for path in "${paths[@]}"; do
          indexPathArr["$i"."$j"]="$path"
          echo "  $j. $path"
          
          j=$((j+1))
        done
        i=$((i+1))
      done
      
      while [ true ]; do
        read -p "输入要恢复的文件序号，格式:日期序号.文件序号, 多个以逗号分隔.(如输入 1.2,3.2)[按enter返回]:" input
        regex='^([0-9]+\.[0-9]+)(,[0-9]+\.[0-9]+)*$'

        if [ -z "$input" ]; then
            return
        fi
      
        if [[ "$input" =~ $regex ]]; then
          declare -a pairNos
          declare -a fileNos 
          IFS=',' read -r -a pairNos <<< "$input"

          echo "请选择文件恢复的目标路径:" 
          echo "1.原路返回 "
          echo "2.${installpath}/restore "
          read -p "请选择:" targetDir

          if [[ "$targetDir" != "1" ]] && [[ "$targetDir" != "2" ]];then
              red "无效输入!"
              return
          fi

          for pairNo in "${pairNos[@]}"; do
            srcpath="${indexPathArr[$pairNo]}"

            if [ "$targetDir" = "1" ]; then
              local user=$(whoami)
              targetPath=${srcpath#*${user}}
              if [ -d $srcpath ]; then
                 targetPath=${targetPath%/*}
              fi
              echo "cp -r $srcpath $HOME/$targetPath"
              cp -r ${srcpath} $HOME/${targetPath}
              
            elif [ "$targetDir" = "2" ]; then
              targetPath="${installpath}/restore"
              if [ ! -e "$targetPath" ]; then
                mkdir -p "$targetPath" 
              fi
              cp -r $srcpath $targetPath/
            fi  
          done
          green "完成文件恢复"
          
        else
          red "输入格式不对，请重新输入！"
        fi
      done
  fi
 
}

uninstall(){
  read -p "确定卸载吗? [y/n] [n]:" input
  input=${input:-n}

  if [ "$input" == "y" ]; then
    delCron
    stopVless
    stopVmess
    stopSingBox
    cd $HOME
    rm -rf serv00-play
    echo "bye!"
  fi
}

InitServer(){
  read -p "$(red "将初始化帐号系统，要继续？[y/n] [n]:")" input
  input=${input:-n}
  read -p "是否保留用户配置？[y/n] [y]:" saveProfile
  saveProfile=${saveProfile:-y}

  if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
    cleanCron
    green "清理进程中..."
    killUserProc
    green "清理磁盘中..."
    if [[ "$saveProfile" = "y" ]] || [[ "$saveProfile" = "Y" ]]; then
      rm -rf ~/* 2>/dev/null
    else
      rm -rf ~/* ~/.* 2>/dev/null
    fi
    cleanPort
    yellow "初始化完毕"
    
   exit 0
  fi
}

installNeZhaAgent(){
  local workedir="${installpath}/serv00-play/nezha"
  if [ ! -e "${workedir}" ]; then
     mkdir -p "${workedir}"
  fi
   cd ${workedir}
   if [[ ! -e nezha-agent ]]; then
    echo "正在下载哪吒探针..."
    local url="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_freebsd_amd64.zip"
    agentZip="nezha-agent.zip"
    if ! wget -qO "$agentZip" "$url"; then
        red "下载哪吒探针失败"
        return 1
    fi
    unzip $agentZip  > /dev/null 2>&1 
    chmod +x ./nezha-agent
    green "下载完毕"
  fi
  
  local config="nezha.json"
  local input="y"
  if [[ -e "$config" ]]; then
    echo "哪吒探针配置如下:"
    cat "$config"
    read -p "是否修改？ [y/n] [n]:" input
    input=${input:-n}
  fi
  
  if [[ "$input" == "y" ]]; then
    read -p "请输入哪吒面板的域名或ip:" nezha_domain
    read -p "请输入哪吒面板RPC端口(默认 5555):" nezha_port
    nezha_port=${nezha_port:-5555}
    read -p "请输入服务器密钥(从哪吒面板中获取):" nezha_pwd
    read -p "是否启用针对 gRPC 端口的 SSL/TLS加密 (--tls)，需要请按 [y]，默认是不需要，不理解用户可回车跳过: " tls
    tls=${tls:-"N"}
  else
    nezha_domain=$(jq -r ".nezha_domain" $config)
    nezha_port=$(jq -r ".nezha_port" $config)
    nezha_pwd=$(jq -r ".nezha_pwd" $config)
  fi

  if [[ -z "$nezha_domain" || -z "$nezha_port" || -z "$nezha_pwd" ]]; then
      red "以上参数都不能为空！"
      return 1
  fi

    cat > $config <<EOF
    {
      "nezha_domain": "$nezha_domain",
      "nezha_port": "$nezha_port",
      "nezha_pwd": "$nezha_pwd",
      "tls": "$tls"
    }
EOF

  local args="--report-delay 4 --disable-auto-update --disable-force-update "
  if [[ "$tls" == "y" ]]; then
     args="${args} --tls "
  fi

  if checknezhaAgentAlive; then
      stopNeZhaAgent
  fi

  nohup ./nezha-agent ${args} -s "${nezha_domain}:${nezha_port}" -p "${nezha_pwd}" >/dev/null 2>&1 &


  green "哪吒探针成功启动!"
  

}

setCnTimeZone(){
  read -p "确定设置中国上海时区? [y/n] [y]:" input
  input=${input:-y}
  
  cd ${installpath}
  if [ "$input" = "y" ]; then
    devil binexec on
    touch .profile
    cat .profile | perl ./serv00-play/mkprofile.pl > tmp_profile
    mv -f tmp_profile .profile
    
    read -p "$(yellow "设置完毕,需要重新登录才能生效，是否重新登录？[y/n] [y]:" )" input
    input=${input:-y}

    if [ "$input" = "y" ]; then
       kill -9 $PPID
    fi
  fi
  
}

setColorWord(){
  cd ${installpath}
  # 定义颜色编码
  bright_black="\033[1;90m"
  bright_red="\033[1;91m"
  bright_green="\033[1;92m"
  bright_yellow="\033[1;93m"
  bright_blue="\033[1;94m"
  bright_magenta="\033[1;95m"
  bright_cyan="\033[1;96m"
  bright_white="\033[1;97m"
  reset="\033[0m"

  # 显示颜色选项列表，并使用颜色着色
  echo -e "请选择一个颜色来输出你的签名:"
  echo -e "1) ${bright_black}明亮黑色${reset}"
  echo -e "2) ${bright_red}明亮红色${reset}"
  echo -e "3) ${bright_green}明亮绿色${reset}"
  echo -e "4) ${bright_yellow}明亮黄色${reset}"
  echo -e "5) ${bright_blue}明亮蓝色${reset}"
  echo -e "6) ${bright_magenta}明亮紫色${reset}"
  echo -e "7) ${bright_cyan}明亮青色${reset}"
  echo -e "8) ${bright_white}明亮白色${reset}"

  # 读取用户输入的选择
  read -p "请输入你的选择(1-8): " color_choice

  read -p "请输入你的大名(仅支持ascii字符):" name

  # 根据用户的选择设置颜色
  case $color_choice in
      1) color_code="90" ;; # 明亮黑色
      2) color_code="91" ;; # 明亮红色
      3) color_code="92" ;; # 明亮绿色
      4) color_code="93" ;; # 明亮黄色
      5) color_code="94" ;; # 明亮蓝色
      6) color_code="95" ;; # 明亮紫色
      7) color_code="96" ;; # 明亮青色
      8) color_code="97" ;; # 明亮白色
      *) echo "无效选择，使用默认颜色 (明亮白色)"; color_code="97" ;;
  esac
  
  if grep "chAngEYourName" .profile > /dev/null ; then
     cat .profile | grep -v "chAngEYourName" > tmp_profile
     echo "echo -e \"\033[1;${color_code}m\$(figlet \"${name}\")\033[0m\"  #chAngEYourName" >> tmp_profile
     mv -f tmp_profile .profile
  else
    echo "echo -e \"\033[1;${color_code}m\$(figlet \"${name}\")\033[0m\" #chAngEYourName" >> .profile
  fi

  read -p  "设置完毕! 重新登录看效果? [y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" == "y" ]]; then
    kill -9 $PPID
  fi

}

showIP(){
  myip="$(curl -s ifconfig.me)"
  green "本机IP: $myip"
}


installMtg(){
   if [ ! -e "mtg" ]; then 
    read -p "请输入使用密码:" password
    if ! checkDownload "mtg"; then
      return 1
    fi
   fi

   chmod +x ./mtg 
   if [ -e "config.json" ]; then 
      echo "已存在配置如下:"
      cat config.json
      read -p "是否重新生成配置? [y/n] [n]:" input
      input=${input:-n}
      if [ "$input" == "n" ]; then
         return 0
      fi
   fi
    
   #自动生成密钥
   host=$(hostname)
   secret=$(./mtg generate-secret --hex $host )
   loadPort
   randomPort tcp mtg
  if [[ -n "$port" ]]; then
      mtpport="$port"
  fi

   cat > config.json <<EOF
   {
      "secret": "$secret",
      "port": "$mtpport"
   }
EOF
   yellow "安装完成!"
}

startMtg(){
  cd ${installpath}/serv00-play

  if [ ! -e "dmtg" ]; then
     ehco "未安装mtproto，请先行安装配置!"
     return 1
  fi
  cd dmtg
  config="config.json"
   if [ ! -e $config ]; then
      red "未安装mtproto，请先行安装配置!"
      return 1
   fi

   if checkMtgAlive; then
     echo "已在运行,请勿重复启动"
     return 0
   fi

   read -p "是否需要日志？: [y/n] [n]:" input
   input=${input:-n}

   if [ "$input" == "y" ]; then
      green "日志文件名称为:mtg.log"
      logfile="-d >mtg.log"
   else
       logfile=" >/dev/null "
   fi

   host="$(hostname | cut -d '.' -f 1)"

   secret=$(jq -r ".secret" $config)
   port=$(jq -r ".port" $config)

   cmd="nohup ./mtg simple-run -n 1.1.1.1 -t 30s -a 1MB 0.0.0.0:${port} ${secret} -c 8192 --prefer-ip=\"prefer-ipv6\" ${logfile} 2>&1 &"
   eval "$cmd"
   sleep 3
   if checkMtgAlive; then
    mtproto="https://t.me/proxy?server=${host}.serv00.com&port=${port}&secret=${secret}"
     echo "$mtproto"
     green "启动成功"
   else 
     echo "启动失败，请检查进程"
   fi

}

stopMtg(){
  r=$(ps aux | grep  mtg | grep -v "grep" | awk '{print $2}' )
  if [ -z "$r" ]; then
    echo "没有运行!"
    return
  else  
    kill -9 $r
  fi
  echo "已停掉mtproto!"

}

mtprotoServ(){
   cd ${installpath}/serv00-play

   if [ ! -e "dmtg" ]; then
      mkdir -p dmtg
   fi
   cd dmtg
   
   echo "1. 安装mtproto代理"
   echo "2. 启动mtproto代理"
   echo "3. 停止mtproto代理"
   read -p "请选择:" input

   if [[ "$input" == "1" ]]; then
      installMtg
   elif [[ "$input" == "2" ]]; then
      startMtg
   elif [[ "$input" == "3" ]]; then
      stopMtg
   else
      red "无效输入"
      return 1
   fi
   
}

extract_user_and_password() {
    output=$1

    username=$(echo "$output" | grep "username:" | sed 's/.*username: //')
    password=$(echo "$output" | grep "password:" | sed 's/.*password: //')
    echo "生成用户密码如下，请谨记! 只会出现一次:"
    green "Username: $username"
    green "Password: $password"
}

update_http_port() {
   cd data || return 1
    local port=$1
    local config_file="config.json"

    if [ -z "$port" ]; then
        echo "Error: No port number provided."
        return 1
    fi
    # 使用 jq 来更新配置文件中的 http_port
    jq --argjson new_port "$port" '.scheme.http_port = $new_port' "$config_file" > tmp.$$.json && mv tmp.$$.json "$config_file"

    echo "配置文件处理完毕."

}

installAlist(){
  cd ${installpath}/serv00-play/ || return 1
  user="$(whoami)"
  if isServ00 ; then
    domain="alist.$user.serv00.net"
  else
    domain="alist.$user.ct8.pl"
  fi
  host="$(hostname | cut -d '.' -f 1)"
  sno=${host/s/web}
  webpath="${installpath}/domains/$domain/public_html/"

   if [[ -d "$webpath/data" && -e "$webpath/alist" ]]; then 
      echo "已安装，请勿重复安装。"
      return 
   else 
      if [ ! -e "alist" ]; then
        mkdir -p  alist
      fi
      cd "alist" || return 1
      if [ ! -e "alist" ]; then
        read -p "请输入使用密码:" password
        if ! checkDownload "alist"; then
          return 1
        fi
      fi
   fi
  loadPort 
  randomPort tcp alist
  if [[ -n "$port" ]]; then
      alist_port="$port"
  fi
  echo "正在安装alist，请等待..."
  resp=$(devil www add $domain proxy localhost $alist_port)
  echo "resp:$resp"
  if [[ ! "$resp" =~ .*succesfully.*$  && ! "$resp" =~ .*Ok.*$ ]]; then 
     if [[ ! "$resp" =~ "This domain already exists" ]]; then 
        red "申请域名$domain 失败！"
        return 1
     fi
  fi
  webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
  resp=$(devil ssl www add $webIp le le $domain)
  
  if [[ ! "$resp" =~ .*succesfully.*$ && ! "$resp" =~ .*Ok.*$ ]]; then 
     red "申请ssl证书失败！$resp"
     read -p "是否可以不要证书使用,后面自己再申请证书？ [y/n] [y]:" input
     input=${input:-y}
     if [[ "$input" != "y" ]]; then
        resp=$(devil www del $domain --remove)
        return 1
     fi
  fi     
  cp ./alist ${installpath}/domains/$domain/public_html/ || return 1
  cd  ${installpath}/domains/$domain/public_html/ || return 1
  rt=$(chmod +x ./alist && ./alist admin random 2>&1 )
  extract_user_and_password "$rt"
  update_http_port "$alist_port"

  green "安装完毕"
  
}

checkAlistAlive(){
   if ps aux | grep alist | grep -v "grep" >/dev/null ; then
      return 0
   else
      return 1
   fi
}

startAlist(){
  user="$(whoami)"
  if isServ00 ; then
    domain="alist.$user.serv00.net"
  else
    domain="alist.$user.ct8.pl"
  fi
  webpath="${installpath}/domains/$domain/public_html/"

  if [[ -d "$webpath/data" && -e "$webpath/alist" ]]; then 
    cd $webpath
    echo "正在启动alist..."
    if  checkAlistAlive; then
      echo "alist已启动，请勿重复启动!"
    else
      nohup ./alist server > /dev/null 2>&1 &
      sleep 3
      if ! checkAlistAlive; then
        red "启动失败，请检查!"
        return 1
      else
        green "启动成功!"
        green "alist管理地址: https://$domain"
      fi
    fi
  else
    red "请先行安装再启动!"
    return     
  fi

}

stopAlist(){
  r=$(ps aux | grep alist| grep -v "grep" | awk '{print $2}' )
  if [ -z "$r" ]; then
    return 0
  else  
    kill -9 $r
  fi
  echo "已停掉alist!"
}

uninstallAlist(){
  read -p "确定卸载alist吗? [y/n] [n]:" input
  input=${input:-n}
  if [[ "$input" == "y" ]]; then
    stopAlist
    user="$(whoami)"
    host="$(hostname | cut -d '.' -f 1)"
    sno=${host/s/web}
  if isServ00 ; then
    domain="alist.$user.serv00.net"
  else
    domain="alist.$user.ct8.pl"
  fi
    webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
    resp=$(devil ssl www del $webIp $domain)
    resp=$(devil www del $domain --remove)
    green "卸载完毕!"
  fi
  
}

resetAdminPass(){
  user="$(whoami)"
  if isServ00 ; then
    domain="alist.$user.serv00.net"
  else
    domain="alist.$user.ct8.pl"
  fi
  webpath="${installpath}/domains/$domain/public_html/"

  cd $webpath
  output=$(./alist admin random 2>&1)
  extract_user_and_password "$output"
}

alistServ(){
   echo "1. 安装部署alist "
   echo "2. 启动alist"
   echo "3. 停掉alist"
   echo "4. 重置admin密码"
   echo "5. 卸载alist"
   read -p "请选择:" input

   if [[ "$input" == "1" ]]; then
     installAlist
   elif [[ "$input" == "2" ]]; then
      startAlist
   elif [[ "$input" == "3" ]]; then
      stopAlist
   elif [[ "$input" == "4" ]]; then
      resetAdminPass
   elif [[ "$input" == "5" ]]; then
      uninstallAlist
   else
      echo "无效输入!"
      return 
   fi
}

declare -a indexPorts
loadIndexPorts(){
  output=$(devil port list)

  indexPorts=()
  # 解析输出内容
  index=0
  while read -r port typ opis; do
      # 跳过标题行
      if [[ "$port" =~ "Port" ]]; then
          continue
      fi
      #echo "port:$port,typ:$typ, opis:$opis"
      if [[ "$port" =~ "Brak" || "$port" =~ "No" ]]; then
          echo "未分配端口"
          return 0
      fi

      if [[ -n "$port" ]]; then
        opis=${opis:-""} 
        indexPorts[$index]="$port|$typ|$opis"
        ((index++)) 
      fi
  done <<< "$output"


}

printIndexPorts() {
  local i=1
  echo "  Port   | Type  |  Description"
  for entry in "${indexPorts[@]}"; do
    # 使用 | 作为分隔符拆分 port、typ 和 opis

    IFS='|' read -r port typ opis <<< "$entry"
    echo "${i}. $port |  $typ | $opis"
    ((i++))
  done
}


delPortMenu(){
  loadIndexPorts

  if [[ ${#indexPorts[@]} -gt 0 ]]; then
     printIndexPorts
     read -p "请选择要删除的端口记录编号(输入0删除所有端口记录, 回车返回):" number
     number=${number:-99}
     
     if [[ $number -eq 99 ]]; then
        return
     elif [[ $number -gt 3 || $number -lt 0 ]]; then
       echo "非法输入!"
       return 
     elif [[ $number -eq 0 ]]; then
       cleanPort
     else 
         idx=$((number-1))
         IFS='|' read -r port typ opis <<< ${indexPorts[$idx]}
         devil port del $typ $port  > /dev/null 2>&1
     fi
      echo "删除完毕!"
  else
     red "未有分配任何端口!"
  fi
        
}

addPortMenu(){
  echo "选择端口类型:"
  echo "1. tcp"
  echo "2. udp"
  read -p "请选择:" co

  if [[ "$co" != "1" && "$co" != "2" ]]; then
    red "非法输入"
    return 
  fi
  local type=""
  if [[ "$co" == "1" ]]; then
     type="tcp"
  else
     type="udp"
  fi
  loadPort
  read -p "请输入端口备注(如hy2，vmess，用于脚本自动获取端口):" opts
  local port=$(getPort $type $opts )
  if [[ "$port" == "failed" ]]; then
    red "分配端口失败,请重新操作!"
  else
    green "分配出来的端口是:$port"
  fi
}

portServ(){
  echo "1. 删除某条端口记录"
  echo "2. 增加一条端口记录"
  echo "3. 返回主菜单"

  read -p "请选择:" input
  input=${input:-3}

  if [[ "$input" == "3" ]]; then
     return 
  elif [[ "$input" == "1" ]]; then
     delPortMenu 
  elif [[ "$input" == "2" ]]; then
     addPortMenu
  else
     echo "无效输入"
     return 
  fi
  
}

cronLE(){
  read -p "请输入定时运行的时间间隔(小时[1-23]):" tm
  tm=${tm:-""}
  if [[ -z "$tm" ]]; then
     red "时间不能为空"
     return 1
  fi   
  if [[ $tm -lt 1 || $tm -gt 23 ]]; then
    red "输入非法!"
    return 1  
  fi
  crontab -l > le.cron
  echo "0 */$tm * * * $workpath/cronSSL.sh $domain > /dev/null 2>&1 " >> le.cron
  crontab le.cron
  rm -rf le.cron
  echo "设置完毕!"
}

applyLE(){
  workpath="${installpath}/serv00-play/ssl"
  cd "$workpath"

  read -p "请输入待申请证书的域名:" domain
  domain=${domain:-""}
  if [[ -z "$domain" ]]; then
     red "域名不能为空"
     return 1
  fi

  inCron="0"
  if crontab -l | grep -F "$domain" > /dev/null 2>&1 ; then
     inCron="1"
     echo "该域名已配置定时申请证书，是否删除定时配置记录，改为手动申请？[y/n] [n]:" input
     input=${input:-n}

     if [[ "$input" == "y" ]]; then
        crontab -l | grep -v "$domain" | crontab -
     fi
  fi
  host="$(hostname | cut -d '.' -f 1)"
  sno=${host/s/web}
  webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
  resp=$(devil ssl www add $webIp le le $domain)

  if [[ ! "$resp" =~ .*succesfully.*$ ]]; then 
     red "申请ssl证书失败！$resp"
     if [[ "$inCron" == "0" ]]; then
        read -p "是否配置定时任务自动申请SSL证书？ [y/n] [y]:" input
        input=${input:-y}
        if [[ "$input" == "y" ]]; then
            cronLE
        fi
     fi
  else
     green "证书申请成功!"
  fi    
}

selfSSL(){
  workpath="${installpath}/serv00-play/ssl"
  cd "$workpath"

  read -p "请输入待申请证书的域名:" self_domain
  self_domain=${self_domain:-""}
  if [[ -z "$self_domain" ]]; then
     red "域名不能为空"
     return 1
  fi
  
  echo "正在生成证书..."

  cat > openssl.cnf <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = req_ext
    x509_extensions = v3_ca # For self-signed certs
    prompt = no

    [req_distinguished_name]
    C = US
    ST = ca
    L = ca
    O = ca
    OU = ca
    CN = $self_domain

    [req_ext]
    subjectAltName = @alt_names

    [v3_ca]
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = $self_domain

EOF
  openssl req -new -newkey rsa:2048 -nodes -keyout _private.key -x509 -days 3650 -out _cert.crt -config openssl.cnf -extensions v3_ca > /dev/null 2>&1 
  if [ $? -ne 0 ]; then
    echo "生成证书失败!"
    return 1
  fi

  echo "已生成证书:"
  green "_private.key"
  green "_cert.crt"

  echo "正在导入证书.."
  host="$(hostname | cut -d '.' -f 1)"
  sno=${host/s/web}
  webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
  resp=$(devil ssl www add "$webIp" ./_cert.crt ./_private.key "$self_domain" )

  if [[ ! "$resp" =~ .*succesfully.*$ ]]; then 
     echo "导入证书失败:$resp"
     return 1
  fi

  echo "导入成功！"
  
}

domainSSLServ(){
   echo "1. 抢域名证书"
   echo "2. 配置自签证书"
   echo "3. 返回主菜单"
  read -p "请选择:" input
  input=${input:-3}

   if [[ "$input" == "3" ]]; then
     return 
  elif [[ "$input" == "1" ]]; then
     applyLE 
  elif [[ "$input" == "2" ]]; then
     selfSSL
  else
     echo "无效输入"
     return 
  fi

}

showMenu(){
  art_wrod=$(figlet "serv00-play")
  echo "<------------------------------------------------------------------>"
  echo -e "${CYAN}${art_wrod}${RESET}"
  echo -e "${GREEN} 饭奇骏频道:https://www.youtube.com/@frankiejun8965 ${RESET}"
  echo -e "${GREEN} TG交流群:https://t.me/fanyousuiqun ${RESET}"
  echo "<------------------------------------------------------------------>"
  echo "请选择一个选项:"

  options=("安装/更新serv00-play项目" "运行vless"  "停止vless"  "配置vless"  "显示vless的节点信息"  "设置保活的项目" "配置sing-box" \
          "运行sing-box" "停止sing-box" "显示sing-box节点信息" "快照恢复" "系统初始化" "设置中国时区及前置工作" "安装/启动/重启哪吒探针" "停止探针" "设置彩色开机字样" "显示本机IP" \
          "mtproto代理" "alist管理" "端口管理" "域名证书管理" "卸载" )

  select opt in "${options[@]}"
  do
      case $REPLY in
          1)
              install
              ;;
          2)
              read -p "请确认${installpath}/serv00-play/vless/vless.json 已配置完毕 (y/n) [y]?" input
              input=${input:-y}
              if [ "$input" != "y" ]; then
                echo "请先进行配置!!!"
                exit 1
              fi
              startVless
              ;;
          3)
              stopVless
              ;;

          4)
              configVless
              ;;
          5)
              showVlessInfo
              ;;
          6)
            setConfig
            ;;
          7)
            configSingBox
            ;;
          8)
            startSingBox
            ;;
         9)
            stopSingBox
            ;;
        10)
            showSingBoxInfo
            ;;
        11)
            ImageRecovery
            ;;
        12)
            InitServer
            ;;
        13)
           setCnTimeZone
           ;;
        14)
           installNeZhaAgent
           ;;
        15)
           stopNeZhaAgent
           ;;
        16)
           setColorWord
           ;;
        17)
           showIP
           ;;
        18)
           mtprotoServ
           ;; 
        19)
           alistServ
           ;;
        20)
           portServ
           ;;
        21)
           domainSSLServ
           ;;
        22)
            uninstall
            ;;
        0)
              echo "退出"
              exit 0
              ;;
          *)
              echo "无效的选项 "
              ;;
      esac
  done

}


showMenu
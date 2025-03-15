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
USER="$(whoami)"
if [[ -e "$installpath/serv00-play" ]]; then
  source ${installpath}/serv00-play/utils.sh
fi

PS3="请选择(输入0退出): "
install() {
  cd ${installpath}
  if [ -d "serv00-play" ]; then
    cd "serv00-play"
    git stash
    if git pull origin main; then
      git fetch --tags
      echo "更新完毕"
      #重新给各个脚本赋权限
      chmod +x ./start.sh
      chmod +x ./keepalive.sh
      chmod +x ./tgsend.sh
      chmod +x ./wxsend.sh
      chmod +x ${installpath}/serv00-play/singbox/start.sh
      chmod +x ${installpath}/serv00-play/singbox/killsing-box.sh
      chmod +x ${installpath}/serv00-play/singbox/autoUpdateHyIP.sh
      chmod +x ${installpath}/serv00-play/ssl/cronSSL.sh
      red "请重新启动脚本!"
      exit 0
    fi
  fi

  cd ${installpath}
  echo "正在安装..."
  if ! git clone https://github.com/frankiejun/serv00-play.git; then
    echo -e "${RED}安装失败!${RESET}"
    exit 1
  fi
  devil binexec on
  touch .profile
  cat .profile | perl ./serv00-play/mkprofile.pl >tmp_profile
  mv -f tmp_profile .profile
  if [[ ! -e "${installpath}/serv00-play" ]]; then
    red "安装不成功！"
    return
  fi

  cd ${installpath}/serv00-play
  chmod +x ./start.sh
  chmod +x ./keepalive.sh
  chmod +x ./tgsend.sh
  chmod +x ./wxsend.sh
  chmod +x ${installpath}/serv00-play/singbox/start.sh
  chmod +x ${installpath}/serv00-play/singbox/killsing-box.sh
  chmod +x ${installpath}/serv00-play/singbox/autoUpdateHyIP.sh
  chmod +x ${installpath}/serv00-play/ssl/cronSSL.sh
  read -p "$(yellow 设置完毕,需要重新登录才能生效，是否重新登录？[y/n] [y]:)" input
  input=${input:-y}

  if [ "$input" = "y" ]; then
    kill -9 $PPID
  fi
  echo -e "${YELLOW}安装成功${RESET}"
}

showSingBoxInfo() {
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

chooseSingbox() {
  echo "保活sing-box中哪个项目(单选): "
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

setConfig() {
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

createConfigFile() {
  echo "选择你要保活的项目（可多选，用空格分隔）:"
  echo "1. sun-panel "
  echo "2. sing-box(包含hy2，vmess，socks5) "
  echo "3. 哪吒探针 "
  echo "4. mtproto代理"
  echo "5. alist"
  echo "6. webssh"
  echo "88. 暂停所有保活功能"
  echo "99. 复通所有保活功能(之前有配置的情况下)"
  echo "0. 返回主菜单"
  item=()

  read -p "请选择: " choices
  choices=($choices)

  if [[ "${choices[@]}" =~ "88" && ${#choices[@]} -gt 1 ]]; then
    red "选择出现了矛盾项，请重新选择!"
    return 1
  fi

  #过滤重复
  choices=($(echo "${choices[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

  # 根据选择来询问对应的配置
  for choice in "${choices[@]}"; do
    case "$choice" in
    0)
      showMenu
      break
      ;;
    1)
      item+=("sun-panel")
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
      item+=("webssh")
      ;;
    88)
      #delCron
      backupConfig "config.json"
      green "设置完毕!"
      return 0
      ;;
    99)
      if [[ ! -e config.bak ]]; then
        red "之前未有配置，未能复通!"
        return 1
      fi
      restoreConfig "config.bak"
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

  read -p "是否使用cron保活? [y/n] [n]:" setcron
  setcron=${setcron:-n}

  if [[ "$setcron" == "y" ]]; then
    read -p "配置保活检查的时间间隔(单位分钟[1~59]，默认5分钟):" tm
    tm=${tm:-"5"}
    json_content+="   \"chktime\": \"$tm\","
  fi
  json_content+="\n \"sendtype\": $sendtype \n"
  json_content+="}\n"

  # 使用 printf 生成文件
  printf "$json_content" >./config.json
  if [[ "$setcron" == "y" ]]; then
    addCron $tm
  fi

  chmod +x ${installpath}/serv00-play/keepalive.sh
  echo -e "${YELLOW} 设置完成! ${RESET} "

}

backupConfig() {
  local filename=$1
  if [[ -e "$filename" ]]; then
    if [[ "$filename" =~ ".json" ]]; then
      local basename=${filename%.json}
      mv $filename $basename.bak
    fi
  fi
}

restoreConfig() {
  local filename=$1
  if [[ -e "$filename" ]]; then
    if [[ "$filename" =~ ".bak" ]]; then
      local basename=${filename%.bak}
      mv $filename $basename.json
    fi
  fi
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
make_outbound_wireguard() {
  cat <<EOF
     {
        "type": "wireguard",
        "tag": "wireguard-out",
        "server": "162.159.195.100",
        "server_port": 4500,
        "local_address": [
                "172.16.0.2/32",
                "2606:4700:110:83c7:b31f:5858:b3a8:c6b1/128"
        ],
        "private_key": "mPZo+V9qlrMGCZ7+E6z2NI6NOV34PD++TpAR09PtCWI=",
        "peer_public_key": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
        "reserved": [
                26,
                21,
                228
        ]
    },
EOF
}

make_outbound_socks5() {
  local server=$1
  local serv_port=$2
  local user=$3
  local pass=$4

  cat >temp_outbound_socks5.json <<EOF
  {
     "type": "socks",
     "tag": "socks5_outbound",
     "server": "$server",
     "server_port": $serv_port,   
     "version": "5",              
     "username": "$user",           
     "password": "$pass"                  
  },
EOF
}

make_hy2_config() {
  cat >temphy2.json <<EOF
   {
       "tag": "hysteria-in",
       "type": "hysteria2",
       "listen": "$hy2_ip",
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

make_socks5_config() {
  cat >tmpsocks5.json <<EOF
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
  local outbound=$1
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

  if [[ "$outbound" == "1" ]]; then
    outboundType="wireguard-out"
  elif [[ "$outbound" == "2" ]]; then
    outboundType="socks5_outbound"
  else
    outboundType="direct"
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
    $([[ "$type" == "1.1" || "$type" == "1.2" || "$type" =~ ^(2.4|2.5|3.1|3.2|4.4|4.5)$ ]] && cat tempvmess.json)
    $comma
    $([[ "$type" == "2" || "$type" =~ ^(3|4)\.[0-9]+$ ]] && cat temphy2.json)
   ],
    "outbounds": [
    $([[ "$outbound" == "1" ]] && make_outbound_wireguard) 
    $([[ "$outbound" == "2" ]] && cat temp_outbound_socks5.json && rm -rf temp_outbound_socks5.json)
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
     "domain": [
             "usher.ttvnw.net",
             "jnn-pa.googleapis.com"
            ],
     "outbound": "$outboundType"
    },
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

generate_random_string() {
  local num=$1
  LC_CTYPE=C xxd </dev/urandom -p | tr -dc 'a-z' | head -c "$num"
  echo
}

localArgo() {
  local configPath="${installpath}/.cloudflared"
  if [[ -e "$configPath/cert.pem" ]]; then
    read -p "已有配置，是否删除重建? [y/n] [n]:" input
    input=${input:-n}
    if [[ "$input" == "y" ]]; then
      #ls -l "$configPath"
      rm -rf "$configPath"/*
    fi
  fi
  sleep 1
  if ! checkDownload "cloudflared"; then
    return
  fi
  echo "请把以下链接copy到浏览器打开，并选择你要作为隧道用的域名(如需中断，请按ctrl+c):"
  rt=$(./cloudflared login)
  echo "$rt"
  read -p "告诉我你选了哪个域名:" domain
  if [[ -z "$domain" ]]; then
    red "未有输入!"
    return 1
  fi
  read -p "是否自动配置隧道信息？[y/n] [y]:" autoflag
  autoflag=${autoflag:-y}

  tunname=""
  if [[ "$autoflag" == "y" ]]; then
    tunname=$(printf "tun-%s" $(generate_random_string 3))
  else
    read -p "请输入隧道名称:" tunname
    if [[ -z "$tunname" ]]; then
      red "未有输入!"
      return 1
    fi
  fi
  green "你所创建的隧道为 $tunname"
  if [[ "$autoflag" == "y" ]]; then
    subname=$(generate_random_string 3)
    domain="$subname"".""$domain"
  else
    read -p "请输入隧道的cname域名:" domain
    if [[ -z "$domain" ]]; then
      red "未有输入!"
      return 1
    fi
  fi
  green "你的cname域名为: $domain"
  port=""
  randomPort tcp vmess
  if [[ -n "$port" ]]; then
    vmport="$port"
  fi

  echo "正在创建本地tunnel..."
  local output=$(./cloudflared tunnel create $tunname)
  if echo "$output" | grep -q "Created"; then
    green "名为 $tunname 的tunnel创建成功!."
    # 提取 .json 文件名
    tunnelid=$(echo "$output" | sed -n 's/.*\/\([a-zA-Z0-9\-]*\)\.json.*/\1/p')
    json_file=$tunnelid".json"
    echo "JSON file: $json_file"
  else
    red "创建隧道名失败! [ $output ]."
  fi

  echo "正在添加隧道的cname域名..."
  ./cloudflared tunnel route dns $tunname $domain
  if [ $? -eq 0 ]; then
    echo "隧道绑定成功！"
  else
    echo "隧道绑定失败！"
  fi

  makeTunnelConfig $tunname $tunnelid $domain $port
}

makeTunnelConfig() {
  local tunnelName=$1
  local tunnelID=$2
  local Domain=$3
  local port=$4
  cat >~/.cloudflared/config.yml <<EOF
tunnel: $tunnelName
credentials-file: ${installpath}/.cloudflared/$tunnelID.json

ingress:
  - hostname: ${Domain}
    service: http://127.0.0.1:${port}
  - service: http_status:404
EOF
}

configSingBox() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
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
        echo "1.本地创建隧道的方式"
        echo "2.到CF建固定隧道方式"
        read -p "请选择:" co

        if [[ "$co" != "1" && "$co" != "2" ]]; then
          echo "无效输入!"
          return 1
        fi

        type=$(echo "$type + 1.1" | bc)
        if [[ "$co" == "1" ]]; then
          tunname=""
          domain=""
          localArgo
        else
          randomPort tcp vmess
          if [[ -n "$port" ]]; then
            vmport="$port"
          fi
          read -p "请输入WSPATH,默认是[serv00]: " wspath
          read -p "请输入ARGO隧道token: " token
          read -p "请输入ARGO隧道的域名: " domain
        fi
        read -p "是否使用自己的优选域名? [y/n] [n]:" input
        input=${input:-n}
        if [[ "$input" == "y" ]]; then
          read -p "请输入优选域名:" goodDomain
          if [[ -z "$goodDomain" ]]; then
            red "未有输入!"
            return 1
          fi
        fi
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
        read -p "请输入优选域名:" goodDomain
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
      echo "自动选择未封ip..."
      hy2_ip=$(get_ip)
      if [[ -n "$hy2_ip" ]]; then
        green "选中未封ip为 $hy2_ip"
      else
        hy2_ip=$(curl -s icanhazip.com)
        red "未能找到未封IP,保持默认值！"
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
        echo "1.本地创建隧道的方式"
        echo "2.到CF建固定隧道方式"
        read -p "请选择:" co

        if [[ "$co" != "1" && "$co" != "2" ]]; then
          echo "无效输入!"
          return 1
        fi
        type="3.1"
        if [[ "$co" == "1" ]]; then
          tunname=""
          domain=""
          localArgo
        else
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
        fi
        read -p "是否使用自己的优选域名? [y/n] [n]:" input
        input=${input:-n}
        if [[ "$input" == "y" ]]; then
          read -p "请输入优选域名:" goodDomain
          if [[ -z "$goodDomain" ]]; then
            red "未有输入!"
            return 1
          fi
        fi
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
        read -p "请输入优选域名:" goodDomain
      fi
      # 配置 hy2
      randomPort udp hy2
      if [[ -n "$port" ]]; then
        hy2_port="$port"
      else
        red "未输入端口号"
        return 1
      fi
      echo "自动选择未封ip..."
      hy2_ip=$(get_ip)
      if [[ -n "$hy2_ip" ]]; then
        green "选中未封ip为 $hy2_ip"
      else
        hy2_ip=$(curl -s icanhazip.com)
        red "未能找到未封IP,保持默认值！"
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

  #socks5 不需要uuid
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

  read -p "是否配置出站? [y/n] [n]:" input
  input=${input:-n}
  outbound=""
  if [[ "$input" == "y" ]]; then
    echo "选择出站协议:"
    echo "1.wireguard "
    echo "2.socks5 "
    read -p "请选择:" co

    if [[ "$co" != "1" && "$co" != "2" ]]; then
      echo "无效输入!"
      return 1
    fi
    outbound=$co

    if [[ "$outbound" == "2" ]]; then
      read -p "请输入socks5服务器域名或IP:" tmpinput
      local out_server=$tmpinput
      if [[ -z "$out_server" ]]; then
        red "未输入内容!"
        return 1
      fi
      read -p "请输入socks5的端口:" tmpinput
      local out_port=$tmpinput
      if [[ -z "$out_port" ]]; then
        red "未输入内容!"
        return 1
      fi
      read -p "请输入socks5的用户名:" tmpinput
      local out_user=$tmpinput
      if [[ -z "$out_user" ]]; then
        red "未输入内容!"
        return 1
      fi
      read -p "请输入socks5的密码:" tmpinput
      local out_pass=$tmpinput
      if [[ -z "$out_pass" ]]; then
        red "未输入内容!"
        return 1
      fi

      make_outbound_socks5 $out_server $out_port $out_user $out_pass
    fi
  fi
  cat >singbox.json <<EOF
  {
     "TYPE": "$type",
     "VMPORT": ${vmport:-null},
     "HY2IP": "${hy2_ip:-'::'}",
     "HY2PORT": ${hy2_port:-null},
     "UUID": "$uuid",
     "WSPATH": "${wspath}",
     "ARGO_AUTH": "${token:-null}",
     "ARGO_DOMAIN": "${domain:-null}",
     "GOOD_DOMAIN": "${goodDomain:-null}",
     "SOCKS5_PORT": "${socks5_port:-null}",
     "SOCKS5_USER": "${username:-null}",
     "SOCKS5_PASS": "${password:-null}",
     "TUNNEL_NAME": "${tunname:-null}"
  }

EOF

  generate_config $outbound
  yellow "sing-box配置完毕!"

}

startSingBox() {
  start_sing_box

}

stopSingBox() {
  stop_sing_box
}

killUserProc() {
  local user=$(whoami)
  pkill -kill -u $user
}

ImageRecovery() {
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
  echo "选择你需要恢复的内容:"
  echo "1. 完整快照恢复 "
  echo "2. 恢复某个文件或目录"
  read -p "请选择:" input

  if [ "$input" = "1" ]; then
    local i=1
    declare -a folders
    for folder in "${sorted_keys[@]}"; do
      echo "${i}. ${folder} "
      i=$((i + 1))
    done
    retries=3
    while [ $retries -gt 0 ]; do
      read -p "请选择恢复到哪一天(序号)？" input
      # 检查输入是否有效
      if [[ $input =~ ^[0-9]+$ ]] && [ "$input" -gt 0 ] && [ "$input" -le $size ]; then
        # 输入有效，退出循环
        targetFolder="${sorted_keys[@]:$input-1:1}"
        echo "你选择的恢复日期是：${targetFolder}"
        break
      else
        # 输入无效，减少重试次数
        retries=$((retries - 1))
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
    rm -rf ~/* >/dev/null 2>&1
    rsync -a $srcpath/ ~/ 2>/dev/null
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
      IFS=$'\n' read -r -d '' -a paths <<<"$results"
      local j=1
      for path in "${paths[@]}"; do
        indexPathArr["$i"."$j"]="$path"
        echo "  $j. $path"

        j=$((j + 1))
      done
      i=$((i + 1))
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
        IFS=',' read -r -a pairNos <<<"$input"

        echo "请选择文件恢复的目标路径:"
        echo "1.原路返回 "
        echo "2.${installpath}/restore "
        read -p "请选择:" targetDir

        if [[ "$targetDir" != "1" ]] && [[ "$targetDir" != "2" ]]; then
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

uninstall() {
  read -p "确定卸载吗? [y/n] [n]:" input
  input=${input:-n}

  if [ "$input" == "y" ]; then
    delCron
    stopSingBox
    cd $HOME
    rm -rf serv00-play
    echo "bye!"
  fi
}

InitServer() {
  read -p "$(red "将初始化帐号系统，要继续？[y/n] [n]:")" input
  input=${input:-n}
  read -p "是否保留用户配置？[y/n] [y]:" saveProfile
  saveProfile=${saveProfile:-y}

  if [[ "$input" == "y" ]] || [[ "$input" == "Y" ]]; then
    cleanCron
    green "清理进程中..."
    killUserProc
    green "清理磁盘中..."
    if [[ "$saveProfile" == "y" ]] || [[ "$saveProfile" == "Y" ]]; then
      rm -rf ~/* 2>/dev/null
    else
      rm -rf ~/* ~/.* 2>/dev/null
      clean_all_domains
      clean_all_dns
      create_default_domain
    fi
    cleanPort
    yellow "初始化完毕"

    exit 0
  fi
}

manageNeZhaAgent() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "-------------------------"
    echo "探针管理："
    echo "1.安装探针"
    echo "2.升级探针"
    echo "3.启动/重启探针"
    echo "4.停止探针"
    echo "9.返回主菜单"
    echo "0.退出脚本"
    yellow "-------------------------"

    read -p "请选择:" choice
    case $choice in
    1)
      installNeZhaAgent
      ;;
    2)
      updateAgent
      ;;
    3)
      startAgent
      exit 0
      ;;
    4)
      stopNeZhaAgent
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

updateAgent() {
  red "暂不提供在线升级, 只适配哪吒面板v0版本系列。"
  return 1
  exepath="${installpath}/serv00-play/nezha/nezha-agent"
  if [ ! -e "$exepath" ]; then
    red "未安装探针，请先安装！！!"
    return
  fi

  local workedir="${installpath}/serv00-play/nezha"
  cd $workedir

  local_version="v"$(./nezha-agent -v)
  latest_version=$(curl -sL https://github.com/nezhahq/agent/releases/latest | sed -n 's/.*tag\/\(v[0-9.]*\).*/\1/p' | head -1)

  if [[ "$local_version" != "$latest_version" ]]; then
    echo "发现新版本: $latest_version，当前版本: $local_version。正在更新..."
    download_url="https://github.com/nezhahq/agent/releases/download/$latest_version/nezha-agent_freebsd_amd64.zip"

    local filezip="nezha-agent_latest.zip"
    curl -sL -o "$filezip" "$download_url"
    if [[ ! -e "$filezip" || -n $(file "$filezip" | grep "text") ]]; then
      echo "下载探针文件失败!"
      return
    fi
    local agent_runing=0
    if checknezhaAgentAlive; then
      stopNeZhaAgent
      agent_runing=1
    fi
    unzip -o $filezip -d .
    chmod +x ./nezha-agent
    if [ $agent_runing -eq 1 ]; then
      startAgent
    fi
    rm -rf $filezip
    green "更新完成！新版本: $latest_version"
  else
    echo "已经是最新版本: $local_version"
  fi
  if [[ $agent_runing -eq 1 ]]; then
    exit 0
  fi
}

startAgent() {
  local workedir="${installpath}/serv00-play/nezha"
  if [ ! -e "${workedir}" ]; then
    red "未安装探针，请先安装！！!"
    return
  fi
  cd $workedir

  local configfile="./nezha.json"
  if [ ! -e "$configfile" ]; then
    red "未安装探针，请先安装！！!"
    return
  fi

  nezha_domain=$(jq -r ".nezha_domain" $configfile)
  nezha_port=$(jq -r ".nezha_port" $configfile)
  nezha_pwd=$(jq -r ".nezha_pwd" $configfile)
  tls=$(jq -r ".tls" $configfile)

  if checknezhaAgentAlive; then
    stopNeZhaAgent
  fi

  local args="--report-delay 4 --disable-auto-update --disable-force-update "
  if [[ "$tls" == "y" ]]; then
    args="${args} --tls "
  fi

  #echo "./nezha-agent ${args} -s ${nezha_domain}:${nezha_port} -p ${nezha_pwd}"
  nohup ./nezha-agent ${args} -s ${nezha_domain}:${nezha_port} -p ${nezha_pwd} >/dev/null 2>&1 &

  if checknezhaAgentAlive; then
    green "启动成功!"
  else
    red "启动失败!"
  fi
  #即便使用nohup放后台，此处如果使用ctrl+c退出脚本，nezha-agent进程也会退出。非常奇葩，因此startAgent后只能exit退出脚本，避免用户使用ctrl+c退出。

}

installNeZhaAgent() {
  local workedir="${installpath}/serv00-play/nezha"
  if [ ! -e "${workedir}" ]; then
    mkdir -p "${workedir}"
  fi

  cd ${workedir}
  if [[ ! -e nezha-agent ]]; then
    echo "正在下载哪吒探针..."
    local url="https://github.com/nezhahq/agent/releases/download/v0.20.3/nezha-agent_freebsd_amd64.zip"
    agentZip="nezha-agent.zip"
    if ! wget -qO "$agentZip" "$url"; then
      red "下载哪吒探针失败"
      return 1
    fi
    unzip $agentZip >/dev/null 2>&1
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
    tls=$(jq -r ".tls" $config)
  fi

  if [[ -z "$nezha_domain" || -z "$nezha_port" || -z "$nezha_pwd" ]]; then
    red "以上参数都不能为空！"
    return 1
  fi

  cat >$config <<EOF
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

uninstallAgent() {
  read -p "确定卸载哪吒探针? [y/n] [n]:" input
  input=${input:-n}

  if [[ "$input" == "y" ]]; then
    if checknezhaAgentAlive; then
      stopNeZhaAgent
    fi
    local workedir="${installpath}/serv00-play/nezha"
    rm -rf $workedir
    green "卸载完毕!"
  fi

}

setCnTimeZone() {
  read -p "确定设置中国上海时区? [y/n] [y]:" input
  input=${input:-y}

  cd ${installpath}
  if [ "$input" = "y" ]; then
    devil binexec on
    touch .profile
    cat .profile | perl ./serv00-play/mkprofile.pl >tmp_profile
    mv -f tmp_profile .profile

    read -p "$(yellow 设置完毕,需要重新登录才能生效，是否重新登录？[y/n] [y]:)" input
    input=${input:-y}

    if [ "$input" = "y" ]; then
      kill -9 $PPID
    fi
  fi

}

setColorWord() {
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
  *)
    echo "无效选择，使用默认颜色 (明亮白色)"
    color_code="97"
    ;;
  esac

  if grep "chAngEYourName" .profile >/dev/null; then
    cat .profile | grep -v "chAngEYourName" >tmp_profile
    echo "echo -e \"\033[1;${color_code}m\$(figlet \"${name}\")\033[0m\"  #chAngEYourName" >>tmp_profile
    mv -f tmp_profile .profile
  else
    echo "echo -e \"\033[1;${color_code}m\$(figlet \"${name}\")\033[0m\" #chAngEYourName" >>.profile
  fi

  read -p "设置完毕! 重新登录看效果? [y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" == "y" ]]; then
    kill -9 $PPID
  fi

}

showIP() {
  myip="$(curl -s icanhazip.com)"
  green "本机IP: $myip"
}

uninstallMtg() {
  read -p "确定卸载? [y/n] [n]:" input
  input=${input:-n}

  if [[ "$input" == "n" ]]; then
    return 1
  fi

  if [[ -e "mtg" ]]; then
    if checkProcAlive mtg; then
      stopMtg
    fi
    cd ${installpath}/serv00-play
    rm -rf dmtg
    green "卸载完毕！"
  fi
}

installMtg() {
  if [ ! -e "mtg" ]; then
    # read -p "请输入使用密码:" password
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
  head=$(hostname | cut -d '.' -f 1)
  no=${head#s}
  host="panel${no}.$(getDoMain)"
  secret=$(./mtg generate-secret --hex $host)
  loadPort
  randomPort tcp mtg
  if [[ -n "$port" ]]; then
    mtpport="$port"
  fi

  cat >config.json <<EOF
   {
      "secret": "$secret",
      "port": "$mtpport"
   }
EOF
  yellow "安装完成!"
}

startMtg() {
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
    mtproto="https://t.me/proxy?server=${host}.$(getDoMain)&port=${port}&secret=${secret}"
    echo "$mtproto"
    green "启动成功"
  else
    echo "启动失败，请检查进程"
  fi

}

stopMtg() {
  r=$(ps aux | grep mtg | grep -v "grep" | awk '{print $2}')
  if [ -z "$r" ]; then
    echo "没有运行!"
    return
  else
    kill -9 $r
  fi
  echo "已停掉mtproto!"

}

mtprotoServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  cd ${installpath}/serv00-play

  if [ ! -e "dmtg" ]; then
    mkdir -p dmtg
  fi
  cd dmtg

  while true; do
    yellow "---------------------"
    echo "服务状态: $(checkProcStatus mtg)"
    echo "mtproto管理:"
    echo "1. 安装"
    echo "2. 启动"
    echo "3. 停止"
    echo "4. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installMtg
      ;;
    2)
      startMtg
      ;;
    3)
      stopMtg
      ;;
    4)
      uninstallMtg
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu

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
  jq --argjson new_port "$port" '.scheme.http_port = $new_port' "$config_file" >tmp.$$.json && mv tmp.$$.json "$config_file"

  echo "配置文件处理完毕."

}

installAlist() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  cd ${installpath}/serv00-play/ || return 1
  alistpath="${installpath}/serv00-play/alist"

  if [[ ! -e "$alistpath" ]]; then
    mkdir -p $alistpath
  fi
  if [[ -d "$alistpath/data" && -e "$alistpath/alist" ]]; then
    echo "已安装，请勿重复安装。"
    return
  else
    cd "alist" || return 1
    if [ ! -e "alist" ]; then
      if ! download_from_net "alist"; then
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
  domain=""
  webIp=""
  if ! makeWWW alist $alist_port; then
    echo "绑定域名失败!"
    return 1
  fi
  if ! applyLE $domain $webIp; then
    echo "申请证书失败!"
    return 1
  fi
  cd $alistpath
  rt=$(chmod +x ./alist && ./alist admin random 2>&1)
  extract_user_and_password "$rt"
  update_http_port "$alist_port"

  green "安装完毕"

}

startAlist() {
  alistpath="${installpath}/serv00-play/alist"
  cd $alistpath
  domain=$(jq -r ".domain" config.json)

  if [[ -d "$alistpath/data" && -e "$alistpath/alist" ]]; then
    cd $alistpath
    echo "正在启动alist..."
    if checkProcAlive alist; then
      echo "alist已启动，请勿重复启动!"
    else
      nohup ./alist server >/dev/null 2>&1 &
      sleep 3
      if ! checkProcAlive alist; then
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

stopAlist() {
  if checkProcAlive "alist"; then
    stopProc "alist"
    sleep 3
  fi

}

# uninstallPHP(){
#   local domain=$1
#   initialize_phpjson
#   delete_domain $domain
#   yellow "已删除域名 $domain 的相关服务!"
# }

uninstallProc() {
  local path=$1
  local procname=$2

  if [ ! -e "$path" ]; then
    red "未安装$procname!!!"
    return 1
  fi
  cd $path
  read -p "确定卸载${procname}吗? [y/n] [n]:" input
  input=${input:-n}
  if [[ "$input" == "y" ]]; then
    stopProc "$procname"
    domain=$(jq -r ".domain" config.json)
    webip=$(jq -r ".webip" config.json)
    resp=$(devil ssl www del $webIp $domain)
    resp=$(devil www del $domain --remove)
    cd ${installpath}/serv00-play
    rm -rf $path
    green "卸载完毕!"
  fi

}

uninstallAlist() {
  alistpath="${installpath}/serv00-play/alist"
  uninstallProc "$alistpath" alist

}

resetAdminPass() {
  alistpath="${installpath}/serv00-play/alist"
  cd $alistpath

  output=$(./alist admin random 2>&1)
  extract_user_and_password "$output"
}

updateAlist() {
  cd ${installpath}/serv00-play/alist || (echo "未安装alist" && return)

  if ! check_update_from_net "alist"; then
    return 1
  fi

  stopAlist
  download_from_net "alist"
  chmod +x ./alist
  startAlist
  echo "更新完毕!"
}

alistServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "----------------------"
    echo "alist:"
    echo "服务状态: $(checkProcStatus alist)"
    echo "1. 安装部署"
    echo "2. 启动"
    echo "3. 停掉"
    echo "4. 重置admin密码"
    echo "5. 更新"
    echo "8. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "----------------------"
    read -p "请选择:" input

    case $input in
    1)
      installAlist
      ;;
    2)
      startAlist
      ;;
    3)
      stopAlist
      ;;
    4)
      resetAdminPass
      ;;
    5)
      updateAlist
      ;;
    8)
      uninstallAlist
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

declare -a indexPorts
loadIndexPorts() {
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
  done <<<"$output"

}

printIndexPorts() {
  local i=1
  echo "  Port   | Type  |  Description"
  for entry in "${indexPorts[@]}"; do
    # 使用 | 作为分隔符拆分 port、typ 和 opis

    IFS='|' read -r port typ opis <<<"$entry"
    echo "${i}. $port |  $typ | $opis"
    ((i++))
  done
}

delPortMenu() {
  loadIndexPorts
  local portNum=${#indexPorts[@]}
  if [[ ${portNum} -gt 0 ]]; then
    printIndexPorts
    read -p "请选择要删除的端口记录编号(输入-1删除所有端口记录, 回车返回):" number
    number=${number:-99}

    if [[ $number -eq 99 ]]; then
      return
    elif [[ $number -gt $portNum || $number -lt -1 || $number -eq 0 ]]; then
      echo "非法输入!"
      return
    elif [[ $number -eq -1 ]]; then
      cleanPort
    else
      idx=$((number - 1))
      IFS='|' read -r port typ opis <<<${indexPorts[$idx]}
      devil port del $typ $port >/dev/null 2>&1
    fi
    echo "删除完毕!"
  else
    red "未有分配任何端口!"
  fi

}

addPortMenu() {
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
  read -p "是否自动分配端口? [y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" == "y" ]]; then
    port=$(getPort $type $opts)
    if [[ "$port" == "failed" ]]; then
      red "分配端口失败,请重新操作!"
    else
      green "分配出来的端口是:$port"
    fi
  else
    read -p "请输入端口号:" port
    if [[ -z "$port" ]]; then
      red "端口不能为空"
      return 1
    fi
    resp=$(devil port add $type $port $opts)
    if [[ "$resp" =~ .*succesfully.*$ || "$resp" =~ .*Ok.*$ ]]; then
      green "添加端口成功!"
    else
      red "添加端口失败!"
    fi
  fi

}

portServ() {
  while true; do
    yellow "----------------------"
    echo "端口管理:"
    echo "1. 删除某条端口记录"
    echo "2. 增加一条端口记录"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "----------------------"
    read -p "请选择:" input
    case $input in
    1)
      delPortMenu
      ;;
    2)
      addPortMenu
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

cronLE() {
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
  crontab -l >le.cron
  echo "0 */$tm * * * $workpath/cronSSL.sh $domain > /dev/null 2>&1 " >>le.cron
  crontab le.cron >/dev/null 2>&1
  rm -rf le.cron
  echo "设置完毕!"
}

get_default_webip() {
  local host="$(hostname | cut -d '.' -f 1)"
  local sno=${host/s/web}
  local webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
  echo "$webIp"
}

applyLE() {
  local domain=$1
  local webIp=$2
  workpath="${installpath}/serv00-play/ssl"
  cd "$workpath"

  if [[ -z "$domain" ]]; then
    read -p "请输入待申请证书的域名:" domain
    domain=${domain:-""}
    if [[ -z "$domain" ]]; then
      red "域名不能为空"
      return 1
    fi
  fi
  inCron="0"
  if crontab -l | grep -F "$domain" >/dev/null 2>&1; then
    inCron="1"
    echo "该域名已配置定时申请证书，是否删除定时配置记录，改为手动申请？[y/n] [n]:" input
    input=${input:-n}

    if [[ "$input" == "y" ]]; then
      crontab -l | grep -v "$domain" | crontab -
    fi
  fi
  if [[ -z "$webIp" ]]; then
    read -p "是否指定webip? [y/n] [n]:" input
    input=${input:-n}
    if [[ "$input" == "y" ]]; then
      read -p "请输入webip:" webIp
      if [[ -z "webIp" ]]; then
        red "webip 不能为空!!!"
        return 1
      fi
    else
      host="$(hostname | cut -d '.' -f 1)"
      sno=${host/s/web}
      webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
    fi
  fi
  #echo "申请证书时，webip是: $webIp"
  resp=$(devil ssl www add $webIp le le $domain)
  if [[ ! "$resp" =~ .*succesfully.*$ ]]; then
    red "申请ssl证书失败！$resp"
    if [[ "$inCron" == "0" ]]; then
      read -p "是否配置定时任务自动申请SSL证书？ [y/n] [n]:" input
      input=${input:-n}
      if [[ "$input" == "y" ]]; then
        cronLE
      fi
    fi
  else
    green "证书申请成功!"
  fi
}

selfSSL() {
  workpath="${installpath}/serv00-play/ssl"
  cd "$workpath"

  read -p "请输入待申请证书的域名:" self_domain
  self_domain=${self_domain:-""}
  if [[ -z "$self_domain" ]]; then
    red "域名不能为空"
    return 1
  fi

  echo "正在生成证书..."

  cat >openssl.cnf <<EOF
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
  openssl req -new -newkey rsa:2048 -nodes -keyout _private.key -x509 -days 3650 -out _cert.crt -config openssl.cnf -extensions v3_ca >/dev/null 2>&1
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
  resp=$(devil ssl www add "$webIp" ./_cert.crt ./_private.key "$self_domain")

  if [[ ! "$resp" =~ .*succesfully.*$ ]]; then
    echo "导入证书失败:$resp"
    return 1
  fi

  echo "导入成功！"

}

domainSSLServ() {
  while true; do
    yellow "---------------------"
    echo "域名证书管理:"
    echo "1. 抢域名证书"
    echo "2. 配置自签证书"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      applyLE
      ;;
    2)
      selfSSL
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

installRoot() {
  workpath="${installpath}/serv00-play/root"
  if [[ ! -e $workpath ]]; then
    mkdir -p "$workpath"
  fi

  if [[ -e "$workpath/MrChrootBSD/mrchroot" ]]; then
    echo "检测到已经安装mrchroot，请勿重复安装!"
    return
  fi
  echo "正在安装..."
  cd $workpath
  git clone https://github.com/nrootconauto/MrChrootBSD.git
  cd MrChrootBSD
  wget https://download.freebsd.org/releases/amd64/14.1-RELEASE/base.txz
  wget https://download.freebsd.org/releases/amd64/14.1-RELEASE/lib32.txz #Needed for gdb for some reason
  mkdir chroot
  cd chroot
  tar xvf ../base.txz
  tar xvf ../lib32.txz
  cd ..
  cmake .
  make
  cp /etc/resolv.conf chroot/etc
  if screen -S rootsession -dm ./mrchroot chroot /bin/sh; then
    echo "安装成功!"
  else
    echo "安装失败!"
  fi

}

enterRoot() {
  workpath="${installpath}/serv00-play/root/MrChrootBSD"
  if [[ ! -e "$workpath/mrchroot" ]]; then
    red "未安装mrchroot，请先行安装!"
    return
  fi

  SESSION_NAME="rootsession"
  if screen -list | grep -q "\.$SESSION_NAME"; then
    echo "进入root..."
    screen -r "$SESSION_NAME"
  else
    echo "未发现root进程，尝试创建井进入root..."
    cd $workpath
    if screen -S $SESSION_NAME -dm ./mrchroot chroot /bin/sh; then
      echo "创建成功!"
      screen -r "$SESSION_NAME"
    else
      echo "创建失败!"
    fi

  fi
}

uninstallRoot() {
  SESSION_NAME="rootsession"

  if [[ ! -e "${installpath}/serv00-play/root" ]]; then
    echo "未安装root，无需卸载!"
    return
  fi

  read -p "确定卸载root吗？[y/n] [n]:" input
  input=${input:-n}

  if [[ "$input" == "y" ]]; then

    if screen -list | grep -q "\.${SESSION_NAME}"; then
      screen -S "$SESSION_NAME" -X quit
    fi

    workpath="${installpath}/serv00-play/"
    cd $workpath
    rm -rf ./root
  fi

  green "卸载完毕!"
}

rootServ() {
  while true; do
    yellow "---------------------"
    echo "一键root:"
    echo "1. 安装root"
    echo "2. 进入root"
    echo "3. 卸载root"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installRoot
      ;;
    2)
      enterRoot
      ;;
    3)
      uninstallRoot
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

showIPStatus() {
  yellow "----------------------------------------------"
  green "  主机名称          |      IP        |  状态"
  yellow "----------------------------------------------"

  show_ip_status
}

checkProcStatus() {
  local procname=$1
  if checkProcAlive $procname; then
    green "运行"
  else
    red "未运行"
  fi

}

sunPanelServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "---------------------"
    echo "sun-panel:"
    echo "服务状态: $(checkProcStatus sun-panel)"
    echo "1. 安装"
    echo "2. 启动"
    echo "3. 停止"
    echo "4. 初始化密码"
    echo "5. 导入serv00账号信息(频道会员尊享功能)"
    echo "8. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installSunPanel
      ;;
    2)
      startSunPanel
      ;;
    3)
      stopSunPanel
      ;;
    4)
      resetSunPanelPwd
      ;;
    5)
      import_accounts
      ;;
    8)
      uninstallSunPanel
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

import_accounts() {
  local workdir="${installpath}/serv00-play/sunpanel"
  if ! vip_statement; then
    return 1
  fi

  cd $workdir
  read -p "请输入会员密码:" passwd
  if ! checkDownload "importd_panel_accounts.sh" 0 "$passwd" 1; then
    return 1
  fi

  chmod +x ./importd_panel_accounts.sh

  ./importd_panel_accounts.sh && rm -rf ./importd_panel_accounts.sh

  if [[ $? -ne 0 ]]; then
    echo "导入失败!"
  else
    echo "导入成功!"
  fi

}

import_accounts() {
  local workdir="${installpath}/serv00-play/sunpanel"
  if ! vip_statement; then
    return 1
  fi

  cd $workdir
  read -s -p "请输入会员密码:" passwd
  if ! checkDownload "importd_panel_accounts.sh" 0 "$passwd" 1; then
    return 1
  fi

  chmod +x ./importd_panel_accounts.sh

  ./importd_panel_accounts.sh && rm -rf ./importd_panel_accounts.sh

  if [[ $? -ne 0 ]]; then
    echo "导入失败!"
  else
    echo "导入成功!"
  fi

}

uninstallSunPanel() {
  local workdir="${installpath}/serv00-play/sunpanel"
  uninstallProc "$workdir" "sun-panel"
}

resetSunPanelPwd() {
  local exepath="${installpath}/serv00-play/sunpanel/sun-panel"
  if [[ ! -e $exepath ]]; then
    echo "未安装，请先安装!"
    return
  fi
  read -p "确定初始化密码? [y/n][n]:" input
  input=${input:-n}

  if [[ "$input" == "y" ]]; then
    local workdir="${installpath}/serv00-play/sunpanel"
    cd $workdir
    ./sun-panel -password-reset
  fi

}

stopSunPanel() {
  stopProc "sun-panel"
  if checkProcAlive "sun-panel"; then
    echo "未能停止，请手动杀进程!"
  fi

}

installSunPanel() {
  local workdir="${installpath}/serv00-play/sunpanel"
  local exepath="${installpath}/serv00-play/sunpanel/sun-panel"
  if [[ -e $exepath ]]; then
    echo "已安装，请勿重复安装!"
    return
  fi
  mkdir -p $workdir
  cd $workdir

  if ! checkDownload "sun-panel"; then
    return 1
  fi
  if ! checkDownload "panelweb" 1; then
    return 1
  fi

  if [[ ! -e "sun-panel" ]]; then
    echo "下载文件解压失败！"
    return 1
  fi
  #初始化密码，并且生成相关目录文件
  ./sun-panel -password-reset

  if [[ ! -e "conf/conf.ini" ]]; then
    echo "无配置文件生成!"
    return 1
  fi

  loadPort
  port=""
  randomPort "tcp" "sun-panel"
  if [ -n "$port" ]; then
    sunPanelPort=$port
  else
    echo "未输入端口!"
    return 1
  fi
  cd conf
  sed -i.bak -E "s/^http_port=[0-9]+$/http_port=${sunPanelPort}/" conf.ini
  cd ..

  domain=""
  webIp=""
  if ! makeWWW panel $sunPanelPort; then
    echo "绑定域名失败!"
    return 1
  fi
  # 自定义域名时申请证书的webip可以从2个ip中选择
  if [ $is_self_domain -eq 1 ]; then
    if ! applyLE $domain $webIp; then
      echo "申请证书失败!"
      return 1
    fi
  else # 没有自定义域名时，webip是内置固定的，就是web(x).serv00.com
    if ! applyLE $domain; then
      echo "申请证书失败!"
      return 1
    fi
  fi
  green "安装完毕!"

}

makeWWW() {
  local proc=$1
  local port=$2
  local www_type=${3:-"proxy"}

  echo "正在处理服务IP,请等待..."
  is_self_domain=0
  webIp=$(get_webip)
  default_webip=$(get_default_webip)
  if [[ -z "$webIp" ]]; then
    webIp=$default_webip
  fi
  green "可用webip是: $webIp, 默认webip是: $default_webip"
  read -p "是否使用自定义域名? [y/n] [n]:" input
  input=${input:-n}
  if [[ "$input" == "y" ]]; then
    is_self_domain=1
    read -p "请输入域名(确保此前域名已指向webip):" domain
  else
    domain=$(getUserDoMain "$proc")
  fi

  if [[ -z "$domain" ]]; then
    red "输入无效域名!"
    return 1
  fi

  domain=${domain,,}
  echo "正在绑定域名,请等待..."
  if [[ "$www_type" == "proxy" ]]; then
    resp=$(devil www add $domain proxy localhost $port)
  else
    resp=$(devil www add $domain php)
  fi
  #echo "resp:$resp"
  if [[ ! "$resp" =~ .*succesfully.*$ && ! "$resp" =~ .*Ok.*$ ]]; then
    if [[ ! "$resp" =~ "This domain already exists" ]]; then
      red "申请域名$domain 失败！"
      return 1
    fi
  fi

  # 自定义域名的特殊处理
  if [[ $is_self_domain -eq 1 ]]; then
    host="$(hostname | cut -d '.' -f 1)"
    sno=${host/s/web}
    default_webIp=$(devil vhost list public | grep "$sno" | awk '{print $1}')
    rid=$(devil dns list "$domain" | grep "$default_webIp" | awk '{print $1}')
    resp=$(echo "y" | devil dns del "$domain" $rid)
    #echo "resp:$resp"
  else
    webIp=$(get_default_webip)
  fi
  # 保存信息
  if [[ "$www_type" == "proxy" ]]; then
    cat >config.json <<EOF
  {
     "webip": "$webIp",
     "domain": "$domain",
     "port": "$port"
  }
EOF
  fi

  green "域名绑定成功,你的域名是:$domain"
  green "你的webip是:$webIp"
}

startSunPanel() {
  local workdir="${installpath}/serv00-play/sunpanel"
  local exepath="${installpath}/serv00-play/sunpanel/sun-panel"
  if [[ ! -e $exepath ]]; then
    red "未安装，请先安装!"
    return
  fi
  cd $workdir
  if checkProcAlive "sun-panel"; then
    stopProc "sun-panel"
  fi
  read -p "是否需要日志($workdir/running.log)? [y/n] [n]:" input
  input=${input:-n}
  local args=""
  if [[ "$input" == "y" ]]; then
    args=" > running.log 2>&1 "
  else
    args=" > /dev/null 2>&1 "
  fi
  cmd="nohup ./sun-panel $args &"
  eval "$cmd"
  sleep 1
  if checkProcAlive "sun-panel"; then
    green "启动成功"
  else
    red "启动失败"
  fi

}

burnAfterReadingServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "---------------------"
    echo "1. 安装"
    echo "2. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installBurnReading
      ;;
    2)
      uninstallBurnReading
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

installBurnReading() {
  local workdir="${installpath}/serv00-play/burnreading"

  if [[ ! -e "$workdir" ]]; then
    mkdir -p $workdir
  fi
  cd $workdir

  if ! check_domains_empty; then
    red "已有安装如下服务，是否继续安装?"
    print_domains
    read -p "继续安装? [y/n] [n]:" input
    input=${input:-n}
    if [[ "$input" == "n" ]]; then
      return 0
    fi
  fi

  domain=""
  webIp=""
  if ! makeWWW burnreading "null" php; then
    echo "绑定域名失败!"
    return 1
  fi

  domainPath="$installpath/domains/$domain/public_html"
  cd $domainPath
  echo "正在下载并安装 OneTimeMessagePHP ..."
  if ! download_from_github_release fkj-src OneTimeMessagePHP OneTimeMessagePHP.zip; then
    red "下载失败!"
    return 1
  fi
  passwd=$(uuidgen -r)
  sed -i '' -e "s/^ENCRYPTION_KEY=.*/ENCRYPTION_KEY=\"$passwd\"/" \
    -e "s|^SITE_DOMAIN=.*|SITE_DOMAIN=\"$domain\"|" "env"
  mv env .env
  echo "已更新配置文件!"

  read -p "是否申请证书? [y/n] [n]:" input
  input=${input:-'n'}
  if [[ "$input" == "y" ]]; then
    echo "正在申请证书，请等待..."
    if ! applyLE $domain $webIp; then
      echo "申请证书失败!"
      return 1
    fi
  fi
  cd $workdir
  add_domain $domain $webIp

  echo "安装完成!"
}

uninstallBurnReading() {
  local workdir="${installpath}/serv00-play/burnreading"

  if [[ ! -e "$workdir" ]]; then
    echo "已没有可以卸载的服务!"
    return 1
  fi

  cd $workdir

  if ! check_domains_empty; then
    echo "目前已安装服务的域名有:"
    print_domains
    read -p "是否删除所有域名服务? [y/n] [n]:" input
    input=${input:-n}
    if [[ "$input" == "y" ]]; then
      delete_all_domains
      rm -rf "${installpath}/serv00-play/burnreading"
    else
      read -p "请输入要删除的服务的域名:" domain
      delete_domain "$domain"
    fi
  else
    echo "没有可卸载服务!"
    echo "目前已安装服务的域名有:"
    print_domains
  fi
  read -p "是否删除所有域名服务? [y/n] [n]:" input
  input=${input:-n}
  if [[ "$input" == "y" ]]; then
    delete_all_domains
    rm -rf "${installpath}/serv00-play/burnreading"
  else
    read -p "请输入要删除的服务的域名:" domain
    delete_domain "$domain"
  fi

}

websshServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "---------------------"
    echo "webssh:"
    echo "服务状态: $(checkProcStatus wssh)"
    echo "1. 安装/修改配置"
    echo "2. 启动"
    echo "3. 停止"
    echo "8. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installWebSSH
      ;;
    2)
      startWebSSH
      ;;
    3)
      stopWebSSH
      ;;
    8)
      uninstallWebSSH
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done
  showMenu
}

uninstallWebSSH() {
  local workdir="${installpath}/serv00-play/webssh"
  uninstallProc "$workdir" "wssh"
}

installWebSSH() {
  local workdir="${installpath}/serv00-play/webssh"
  if [[ ! -e "$workdir" ]]; then
    mkdir -p $workdir
  fi
  cd $workdir
  configfile="./config.json"
  local is_installed=0
  if [ -e "$configfile" ]; then
    is_installed=1
    echo "已安装，配置如下:"
    cat $configfile

    read -p "是否修改配置? [y/n] [n]:" input
    input=${input:-n}
    if [[ "$input" == "n" ]]; then
      return
    fi
  fi

  port=""
  loadPort
  randomPort tcp "webssh"
  if [ -n "$port" ]; then
    websshPort=$port
  else
    echo "未输入端口!"
    return 1
  fi

  #   cat > $configfile <<EOF
  #   {
  #     "port": $websshPort
  #   }
  # EOF

  if [[ $is_installed -eq 0 ]]; then
    echo "正在安装webssh..."
    pip install webssh
  fi

  user="$(whoami)"
  target_path="/home/$user/.local/bin"
  wsshpath="$target_path/wssh"
  if [[ ! -e "$wsshpath" ]]; then
    red "安装webssh失败 !"
    return 1
  fi
  cp $wsshpath $workdir
  profile="${installpath}/.profile"

  if ! grep -q "export PATH=.*$target_path" "$profile"; then
    echo "export PATH=$target_path:\$PATH" >>"$profile"
    source $profile
  fi
  domain=""
  webIp=""
  if ! makeWWW ssh $websshPort; then
    echo "绑定域名失败!"
    return 1
  fi
  if ! applyLE $domain $webIp; then
    echo "申请证书失败!"
    return 1
  fi
  echo "安装完成!"

}

stopWebSSH() {
  stopProc "wssh"
  sleep 2
  if ! checkProcAlive "wssh"; then
    echo "wssh已停止！"
  else
    echo "未能停止，请手动杀进程!"
  fi
}

startWebSSH() {
  local workdir="${installpath}/serv00-play/webssh"
  local configfile="$workdir/config.json"
  if [ ! -e "$configfile" ]; then
    echo "未安装，请先安装!"
    return
  fi
  cd $workdir
  read -p "是否需要日志($workdir/running.log)? [y/n] [n]:" input
  input=${input:-n}
  args=""
  if [[ "$input" == "y" ]]; then
    args=" > running.log 2>&1 "
  else
    args=" > /dev/null 2>&1 "
  fi
  port=$(jq -r ".port" $configfile)
  if checkProcAlive "wssh"; then
    stopProc "wssh"
  fi
  echo "正在启动中..."
  cmd="nohup ./wssh --port=$port --wpintvl=30 --fbidhttp=False --xheaders=False --encoding='utf-8' --delay=10  $args &"
  eval "$cmd"
  sleep 2
  if checkProcAlive wssh; then
    green "启动成功！"
  else
    echo "启动失败!"
  fi
}

nonServ() {
  cat <<EOF
   占坑位，未开发功能，敬请期待！
   如果你知道有好的项目，可以到我的频道进行留言投稿，
   我会分析可行性，择优取录，所以你喜欢的项目有可能会集成到serv00-play的项目中。
   留言板：https://t.me/fanyou_channel/40
EOF
}

checkInstalled() {
  local model=$1
  if [[ "$model" == "serv00-play" ]]; then
    if [[ ! -d "${installpath}/$model" ]]; then
      red "请先安装$model !!!"
      return 1
    else
      return 0
    fi
  else
    if [[ ! -d "${installpath}/serv00-play/$model" ]]; then
      red "请先安装$model !!!"
      return 1
    else
      return 0
    fi
  fi
  return 1
}

changeHy2IP() {
  cd ${installpath}/serv00-play/singbox
  if [[ ! -e "singbox.json" || ! -e "config.json" ]]; then
    red "未安装节点，请先安装!"
    return 1
  fi
  showIPStatus
  read -p "是否让程序为HY2选择可用的IP？[y/n] [y]:" input
  input=${input:-y}

  if [[ "$input" == "n" ]]; then
    read -p "是否手动选择IP？[y/n] [y]:" choose
    choose=${choose:-y}
    if [[ "$choose" == "y" ]]; then
      read -p "请选择你要的IP的序号:" num
      if [[ -z "$num" ]]; then
        red "选择不能为空!"
        return 1
      fi
      if [[ $num -lt 1 || $num -gt ${#localIPs[@]} ]]; then
        echo "错误：num 的值非法！请输入 1 到 ${#localIPs[@]} 之间的整数。"
        return 1
      fi
      hy2_ip=${localIPs[$((num - 1))]}
    else
      return 1
    fi
  else
    hy2_ip=$(get_ip)
  fi

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
  stopSingBox
  startSingBox

}

linkAliveServ() {
  workdir="${installpath}/serv00-play/linkalive"
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  if ! vip_statement "linkAliveStatment"; then
    return 1
  fi

  if [[ ! -e $workdir ]]; then
    mkdir -p $workdir
  fi
  cd $workdir

  read -s -p "请输入会员密码:" passwd
  #判断密码是否为空
  if [[ -z "$passwd" ]]; then
    red "密码不能为空!"
    return 1
  fi
  if ! checkDownload "linkAlive.sh" $ISFILE "$passwd" $ISVIP; then
    return 1
  fi

  chmod +x ./linkAlive.sh
  ./linkAlive.sh "$passwd"

  #showMenu
}

keepAliveServ() {
  if ! checkInstalled "serv00-play"; then
    return 1
  fi
  while true; do
    yellow "---------------------"
    echo "keepAlive:"
    echo "1. 安装"
    echo "2. 更新(须先按1更新serv00-play)"
    echo "3. 更新保活时间间隔"
    echo "4. 修改token"
    echo "8. 卸载"
    echo "9. 返回主菜单"
    echo "0. 退出脚本"
    yellow "---------------------"
    read -p "请选择:" input

    case $input in
    1)
      installkeepAlive
      ;;
    2)
      updatekeepAlive
      ;;
    3)
      setKeepAliveInterval
      ;;
    4)
      changeKeepAliveToken
      ;;
    8)
      uninstallkeepAlive
      ;;
    9)
      break
      ;;
    0)
      exit 0
      ;;
    *)
      echo "无效选项，请重试"
      ;;
    esac
  done

  showMenu
}

installkeepAlive() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  local domainPath="${installpath}/domains/$domain/public_nodejs"
  local workdir="${installpath}/serv00-play/keepalive"
  if [[ -e "$domainPath/config.json" ]]; then
    red "已安装,请勿重复安装!"
    return 1
  fi
  cd $workdir

  read -p "需要使用默认域名[$domain]进行安装，若继续安装将会删除默认域名，确认是否继续? [y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" != "y" ]]; then
    echo "取消安装"
    return 1
  fi
  delDefaultDomain
  echo "正在安装..."
  if ! createDefaultDomain; then
    return 1
  fi
  mv "$domainPath/public" "$domainPath/static"
  cp ./nezha.jpg $domainPath/static
  cp ./config.json $domainPath
  cp ./app.js $domainPath

  cd $domainPath
  if ! npm22 install express body-parser child_process fs; then
    red "安装依赖失败"
    return 1
  fi

  read -p "是否需要自定义token? [y/n] [y]:" input
  input=${input:-y}
  if [[ "$input" == "y" ]]; then
    uuid=""
    read -p "请输入token:" uuid
    if [[ -z "$uuid" ]]; then
      red "token不能为空!"
      return 1
    fi
  else
    uuid=$(uuidgen)
  fi
  green "你的token是:$uuid"
  sed -i '' "s/uuid/$uuid/g" config.json
  read -p "输入保活时间间隔(单位:分钟)[默认:2分钟]:" interval
  interval=${interval:-2}
  sed -i '' "s/TM/$interval/g" config.json

  green "安装成功"

}

uninstallkeepAlive() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  local domainPath="${installpath}/domains/$domain/public_nodejs"
  read -p "是否卸载? [y/n] [n]:" input
  input=${input:-n}
  if [[ "$input" != "y" ]]; then
    return 1
  fi
  domainPath="${installpath}/domains/$domain/public_nodejs"
  if ! delDefaultDomain; then
    return 1
  fi
  green "卸载成功"
}

createDefaultDomain() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  rt=$(devil www add $domain nodejs /usr/local/bin/node22 production)
  if [[ ! "$rt" =~ .*succesfully*$ ]]; then
    red "创建默认域名失败"
    return 1
  fi
}

delDefaultDomain() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  rt=$(devil www del $domain --remove)
  if [[ ! "$rt" =~ .*deleted*$ ]]; then
    red "删除默认域名失败"
    return 1
  fi
}

updatekeepAlive() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  domainPath="${installpath}/domains/$domain/public_nodejs"
  workDir="$installpath/serv00-play/keepalive"
  if [[ ! -e "$domainPath/config.json" ]]; then
    red "未安装,请先安装!"
    return 1
  fi
  if [[ ! -e "$workDir" ]]; then
    mkdir -p $workDir
  fi
  cd $workDir

  cp ./app.js $domainPath

  cp $workDir/app.js $domainPath
  devil www restart $domain
  green "更新成功"
}

changeKeepAliveToken() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  domainPath="${installpath}/domains/$domain/public_nodejs"
  if [[ ! -e "$domainPath/config.json" ]]; then
    red "未安装,请先安装!"
    return 1
  fi

  cur_token=$(jq -r ".token" $domainPath/config.json)
  echo "当前token为: $cur_token"
  token=""
  read -p "输入新的token:" token
  if [[ -z "$token" ]]; then
    red "token不能为空!"
    return 1
  fi
  upInsertFd $domainPath/config.json token $token
  if [ $? -ne 0 ]; then
    red "更新失败!"
    return 1
  fi
  green "更新成功"
}

setKeepAliveInterval() {
  local domain=$(getUserDoMain)
  domain="${domain,,}"
  domainPath="${installpath}/domains/$domain/public_nodejs"
  if [[ ! -e "$domainPath/config.json" ]]; then
    red "未安装,请先安装!"
    return 1
  fi

  cur_interval=$(jq -r ".interval" $domainPath/config.json)
  echo "当前保活时间间隔为: $cur_interval 分钟"
  read -p "输入保活时间间隔(单位:分钟)[默认:2分钟]:" interval
  interval=${interval:-2}
  upInsertFd $domainPath/config.json interval $interval
  if [ $? -ne 0 ]; then
    red "更新失败!"
    return 1
  fi
  green "更新成功"
}

linkAliveStatment() {
  cat <<EOF
     全新的保活方式，无需借助cron，也不需要第三方平台(github/青龙/vps等登录方式)进行保活。 
  在使用代理客户端的同时自动保活，全程无感！
EOF
}

vip_statement() {
  statement=$1
  echo "此功能为会员尊享功能，欢迎加入饭奇骏频道会员: https://www.youtube.com/channel/UCjS3UKSmQ2mvsThXhJIFobA/join  "
  $statement
  read -p "你是否会员? [y/n] [n]:" input
  input=${input:-n}

  if [[ "$input" == "n" ]]; then
    return 1
  fi

  return 0
}

getLatestVer() {
  ver=$(git ls-remote --tags https://github.com/frankiejun/serv00-play.git | awk -F/ '{print $3}' | sort -V | tail -n 1)
  echo $ver
}
getCurrentVer() {
  ver=$(git describe --tags --abbrev=0 2>/dev/null)
  if [ $? -ne 0 ]; then
    echo null
  else
    echo $ver
  fi
}

showMenu() {
  art_wrod=$(figlet "serv00-play")
  echo "<------------------------------------------------------------------>"
  echo -e "${CYAN}${art_wrod}${RESET}"
  echo -e "${GREEN} 饭奇骏频道:https://www.youtube.com/@frankiejun8965 ${RESET}"
  echo -e "${GREEN} TG交流群:https://t.me/fanyousuiqun ${RESET}"
  echo -e "${GREEN} 当前版本号:$(getCurrentVer) 最新版本号:$(getLatestVer) ${RESET}"
  echo "<------------------------------------------------------------------>"
  echo "请选择一个选项:"

  options=("安装/更新serv00-play项目" "sun-panel" "webssh" "阅后即焚" "linkalive" "设置保活的项目" "配置sing-box"
    "运行sing-box" "停止sing-box" "显示sing-box节点信息" "快照恢复" "系统初始化" "前置工作及设置中国时区" "管理哪吒探针" "卸载探针" "设置彩色开机字样" "显示本机IP"
    "mtproto代理" "alist管理" "端口管理" "域名证书管理" "一键root" "自动检测主机IP状态" "一键更换hy2的IP" "KeepAlive" "卸载")

  select opt in "${options[@]}"; do
    case $REPLY in
    1)
      install
      ;;
    2)
      sunPanelServ
      ;;
    3)
      websshServ
      ;;
    4)
      burnAfterReadingServ
      ;;
    5)
      linkAliveServ
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
      manageNeZhaAgent
      ;;
    15)
      uninstallAgent
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
      rootServ
      ;;
    23)
      showIPStatus
      ;;
    24)
      changeHy2IP
      ;;
    25)
      keepAliveServ
      ;;
    26)
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

#!/bin/bash

config="singbox.json"
installpath="$HOME"
VMPORT=$(jq -r ".VMPORT" $config)
HY2PORT=$(jq -r ".HY2PORT" $config)
HY2IP=$(jq -r ".HY2IP" $config)
UUID=$(jq -r ".UUID" $config)
WSPATH=$(jq -r ".WSPATH" $config)

ARGO_AUTH=$(jq -r ".ARGO_AUTH" $config)
ARGO_DOMAIN=$(jq -r ".ARGO_DOMAIN" $config)
TUNNEL_NAME=$(jq -r ".TUNNEL_NAME" $config)
GOOD_DOMAIN=$(jq -r ".GOOD_DOMAIN" $config)
SOCKS5_PORT=$(jq -r ".SOCKS5_PORT" $config)
SOCKS5_USER=$(jq -r ".SOCKS5_USER" $config)
SOCKS5_PASS=$(jq -r ".SOCKS5_PASS" $config)
user="$(whoami)"

if [ -z $1 ]; then
  type=$(jq -r ".TYPE" $config)
else
  type=$1
fi

keep=$2

run() {
  if ps aux | grep cloudflared | grep -v "grep" >/dev/null; then
    return
  fi
  if [[ "${ARGO_AUTH}" != "null" && "${ARGO_DOMAIN}" != "null" ]]; then
    nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 &
  elif [[ "$ARGO_DOMAIN" != "null" && "$TUNNEL_NAME" != "null" ]]; then
    nohup ./cloudflared tunnel run $TUNNEL_NAME >/dev/null 2>&1 &
  else
    echo "未有tunnel相关配置！"
    return 1
  fi
}

uploadList() {
  local token="$1"
  local content="$2"
  local user="${user,,}"
  local url="${linkBaseurl}/addlist?token=$token"
  local encode_content=$(echo -n "$content" | base64 -w 0)

  #echo "encode_content:$encode_content"
  curl -X POST "$url" \
    -H "Content-Type: application/json" \
    -d "{\"content\":\"$encode_content\",
    \"user\":\"$user\"}"

  if [[ $? -eq 0 ]]; then
    return 0
  else
    return 1
  fi
}

export_list() {
  user="$(whoami)"
  host="$(hostname | cut -d '.' -f 1)"
  if [[ "$HY2IP" != "::" ]]; then
    myip=${HY2IP}
  else
    myip="$(curl -s icanhazip.com)"
  fi
  if [[ "$GOOD_DOMAIN" == "null" ]]; then
    GOOD_DOMAIN="www.visa.com.hk"
  fi
  vmessname="Argo-vmess-$host-$user"
  hy2name="Hy2-$host-$user"
  VMESSWS="{ \"v\":\"2\", \"ps\": \"Vmessws-${host}-${user}\", \"add\":\"$GOOD_DOMAIN\", \"port\":\"443\", \"id\": \"${UUID}\", \"aid\": \"0\",  \"scy\": \"none\",  \"net\": \"ws\",  \"type\": \"none\",  \"host\": \"${GOOD_DOMAIN}\",  \"path\": \"/${WSPATH}?ed=2048\",  \"tls\": \"tls\",  \"sni\": \"${GOOD_DOMAIN}\",  \"alpn\": \"\",  \"fp\": \"\"}"
  ARGOVMESS="{ \"v\": \"2\", \"ps\": \"$vmessname\", \"add\": \"$GOOD_DOMAIN\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\",  \"fp\": \"\" }"
  hysteria2="hysteria2://$UUID@$myip:$HY2PORT/?sni=www.bing.com&alpn=h3&insecure=1#$hy2name"
  socks5="https://t.me/socks?server=${host}.serv00.com&port=${SOCKS5_PORT}&user=${SOCKS5_USER}&pass=${SOCKS5_PASS}"
  proxyip="proxyip://${SOCKS5_USER}:${SOCKS5_PASS}@${host}.serv00.com:${SOCKS5_PORT}"

  cat >list <<EOF
*******************************************
V2-rayN:
----------------------------

$([[ "$type" =~ ^(1.1|3.1|4.4|2.4)$ ]] && echo "vmess://$(echo ${ARGOVMESS} | base64 -w0)")
$([[ "$type" =~ ^(1.2|3.2|4.5|2.5)$ ]] && echo "vmess://$(echo ${VMESSWS} | base64 -w0)")
$([[ "$type" =~ ^(2|3.3|3.1|3.2|4.4|4.5)$ ]] && echo $hysteria2 && echo "")
$([[ "$type" =~ ^(1.3|2.4|2.5|3.3|4.4|4.5)$ ]] && echo $socks5 && echo "")
$([[ "$type" =~ ^(1.3|2.4|2.5|3.3|4.4|4.5)$ ]] && echo $proxyip && echo "")

EOF
  cat list
  if [[ -e "${installpath}/serv00-play/linkalive/linkAlive.sh" ]]; then
    local domain="$user.serv00.net"
    domain="${domain,,}"
    local linkBaseurl="https://la.fkj.pp.ua"
    if [[ -e "${installpath}/domains/$domain/public_nodejs/config.json" ]]; then
      token=$(jq -r ".token" "${installpath}/domains/$domain/public_nodejs/config.json")
      if [[ -n "$token" ]]; then
        content=$(cat ./list | grep -E "vmess|hyster")
        if uploadList "$token" "$content"; then
          echo " "
        fi
      fi
    fi
  fi
}

if [ "$keep" = "list" ]; then
  export_list
  exit 0
fi
#echo "type:$type"
#如果只有argo+vmess
#type=1,3 的处理只是为了兼容旧配置
if [[ "$type" =~ ^(1|3|1.1|3.1|4.4|2.4)$ ]]; then
  run
fi

#如果只有hy2和vmess+ws/socks5
if [[ "$type" =~ ^(1.2|1.3|2|2.5|3.2|3.3|4.5)$ ]]; then
  r=$(ps aux | grep cloudflare | grep -v grep | awk '{print $2}')
  if [ -n "$r" ]; then
    #echo $r
    kill -9 $r
  fi
  chmod +x ./serv00sb
  if ! ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    nohup ./serv00sb run -c ./config.json >/dev/null 2>&1 &
  fi
elif [[ "$type" =~ ^(1|3|1.1|3.1|4.4|2.4)$ ]]; then
  chmod +x ./serv00sb
  if ! ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    nohup ./serv00sb run -c ./config.json >/dev/null 2>&1 &
  fi
fi

if [ -z "$keep" ]; then
  export_list
fi
exit 0

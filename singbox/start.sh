#!/bin/bash

config="singbox.json"

VMPORT=$(jq -r ".VMPORT" $config)
HY2PORT=$(jq -r ".HY2PORT" $config)
HY2IP=$(jq -r ".HY2IP" $config)
UUID=$(jq -r ".UUID" $config)
WSPATH=$(jq -r ".WSPATH" $config)

ARGO_AUTH=$(jq -r ".ARGO_AUTH" $config)
ARGO_DOMAIN=$(jq -r ".ARGO_DOMAIN" $config)

GOOD_DOMAIN=$(jq -r ".GOOD_DOMAIN" $config)
SOCKS5_PORT=$(jq -r ".SOCKS5_PORT" $config)
SOCKS5_USER=$(jq -r ".SOCKS5_USER" $config)
SOCKS5_PASS=$(jq -r ".SOCKS5_PASS" $config)


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
  if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
    if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
      echo "$ARGO_AUTH" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' >tunnel.json
      cat >tunnel.yml <<EOF
tunnel: $(sed "s@.*TunnelID:(.*)}@\1@g" <<<"$ARGO_AUTH")
credentials-file: /app/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:${VMPORT}
EOF
      cat >>tunnel.yml <<EOF
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
      nohup ./cloudflared tunnel --edge-ip-version auto --config tunnel.yml run >/dev/null 2>&1 &
    elif [[ "$ARGO_AUTH" =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 run --token ${ARGO_AUTH} >/dev/null 2>&1 &
    fi
  else
    nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --url http://localhost:${VMPORT} >/dev/null 2>&1 &
    sleep 5
    ARGO_DOMAIN=$(wget -qO- $(sockstat -4 -l -P tcp | grep cloudflare | awk '{for(i=1;i<=NF;i++) if($i ~ /127\.0\.0\.1/) print $i}')/quicktunnel | jq -r '.hostname')
    echo "ARGO_DOMAIN:$ARGO_DOMAIN"
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
  vmessname="Argo-vmess-$host-$user"
  hy2name="Hy2-$host-$user"
  VMESSWS="{\"v\":\"2\",\"ps\": \"Vmessws-${host}-${user}\", \"add\":\"www.visa.com.hk\", \"port\":\"443\", \"id\": \"${UUID}\", \"aid\": \"0\",  \"scy\": \"none\",  \"net\": \"ws\",  \"type\": \"none\",  \"host\": \"${GOOD_DOMAIN}\",  \"path\": \"/${WSPATH}?ed=2048\",  \"tls\": \"tls\",  \"sni\": \"${GOOD_DOMAIN}\",  \"alpn\": \"\",  \"fp\": \"\"}"
  ARGOVMESS="{ \"v\": \"2\", \"ps\": \"$vmessname\", \"add\": \"www.visa.com.hk\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  hysteria2="hysteria2://$UUID@$myip:$HY2PORT/?sni=www.bing.com&alpn=h3&insecure=1#$hy2name"
  socks5="https://t.me/socks?server=${host}.serv00.com&port=${SOCKS5_PORT}&user=${SOCKS5_USER}&pass=${SOCKS5_PASS}"
  proxyip="proxyip://${SOCKS5_USER}:${SOCKS5_PASS}@${host}.serv00.com:${SOCKS5_PORT}"
 

  cat >list <<EOF
*******************************************
V2-rayN:
----------------------------

$([[ "$type" =~ ^(1.1|3.1|4.4|2.4)$ ]] && echo "vmess://$(echo -n ${ARGOVMESS} | base64 | tr -d '\n')")
$([[ "$type" =~ ^(1.2|3.2|4.5|2.5)$  ]] && echo "vmess://$(echo -n ${VMESSWS} | base64 | tr -d '\n')")
$([[ "$type" =~ ^(2|3.3|3.1|3.2|4.4|4.5)$ ]] && echo $hysteria2)
$([[ "$type" =~ ^(1.3|2.4|2.5|3.3|4.4|4.5)$ ]] && echo $socks5)
$([[ "$type" =~ ^(1.3|2.4|2.5|3.3|4.4|4.5)$ ]] && echo $proxyip)

EOF
  cat list
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

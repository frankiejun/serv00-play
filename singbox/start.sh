#!/bin/bash

config="singbox.json"

VMPORT=$(jq -r ".VMPORT" $config)
HY2PORT=$(jq -r ".HY2PORT" $config)

UUID=$(jq -r ".UUID" $config)
WSPATH=$(jq -r ".WSPATH" $config)

ARGO_AUTH=$(jq -r ".ARGO_AUTH" $config)
ARGO_DOMAIN=$(jq -r ".ARGO_DOMAIN" $config)

if [ -z $1 ]; then
  type=$(jq -r ".TYPE" $config)
else
  type=$1
fi

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
  myip="$(curl -s ifconfig.me)"
  vmessname="Argo-vmess-$host-$user"
  hy2name="Hy2-$host-$user"
  VMESS="{ \"v\": \"2\", \"ps\": \"$vmessname\", \"add\": \"www.visa.com.tw\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  hysteria2="hysteria2://$UUID@$myip:$HY2PORT/?sni=www.bing.com&alpn=h3&insecure=1#$hy2name"

  cat >list <<EOF
*******************************************
V2-rayN:
----------------------------
$([[ "$type" == "1" || "$type" == "3" ]] && echo "vmess://$(echo -n ${VMESS} | base64 | tr -d '\n')")
$([[ "$type" == "2" || "$type" == "3" ]] && echo $hysteria2)

EOF
  cat list
}

if [[ "$type" == "1" || "$type" == "3" ]]; then
  run
fi
if [[ "$type" == "1" || "$type" == "2" || "$type" == "3" ]]; then
  chmod +x ./serv00sb
  if ps aux | grep serv00sb | grep -v "grep" >/dev/null; then
    exit 0
  fi
  nohup ./serv00sb run -c ./config.json >/dev/null 2>&1 &

fi
export_list

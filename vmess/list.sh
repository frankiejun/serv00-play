#!/bin/bash

GREEN='\033[0;32m'
RESET='\033[0m'
param=$1
argo_token=$(jq -r ".ARGO_AUTH" vmess.json)
argo_domain=$(jq -r ".ARGO_DOMAIN" vmess.json)
uuid=$(jq -r ".UUID" vmess.json)
webport=$(jq -r ".WEBPORT" vmess.json)
host=$(curl -s https://ifconfig.me/)
ARGO_AUTH=${argo_token/null/}
ARGO_DOMAIN=${argo_domain/null/}

if [ -z $ARGO_DOMAIN ]; then
     ARGO_DOMAIN=$(wget -qO- $(sockstat -4 -l -P tcp | grep cloudflare | awk '{for(i=1;i<=NF;i++) if($i ~ /127\.0\.0\.1/) print $i}')/quicktunnel | jq -r '.hostname')
fi

urlStr="http://$host:$webport/$uuid/vm"
export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-k0baya-Vmess\", \"add\": \"alejandracaiccedo.com\", \"port\": \"443\", \"id\": \"${uuid}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/serv00-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  cat > list << EOF
*******************************************
V2-rayN:
----------------------------
vmess://$(echo -n ${VMESS} | base64 | tr -d '\n')
小火箭:
----------------------------
vmess://bm9uZToxYWE0ZjE5OS0wMGYzLTQ5MTYtOGQ3NS0wZTQ5OTAwZTU2NmVAYWxlamFuZHJhY2FpY2NlZG8uY29tOjQ0Mw==?remarks=Argo-k0baya-Vmess&obfsParam=${ARGO_DOMAIN}&path=/serv00-vmess?ed=2048&obfs=websocket&tls=1&peer=${ARGO_DOMAIN}&alterId=0
*******************************************
Clash:
----------------------------
- {name: Argo-k0baya-Vmess, type: vmess, server: alejandracaiccedo.com, port: 443, uuid: 1aa4f199-00f3-4916-8d75-0e49900e566e, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /serv00-vmess?ed=2048, headers: {Host: ${ARGO_DOMAIN}}}, udp: true}
*******************************************
EOF
  cat list
}
export_list

if [ -n $param ] && [ "$param" = "main" ];then
	echo -e "订阅链接:"
	echo -e "${GREEN} $urlStr  ${RESET}"
fi





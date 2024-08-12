#!/usr/bin/env bash

ARGO_AUTH=
ARGO_DOMAIN=

# 下载并运行 Argo
check_file() {
  [ ! -e cloudflared ] && wget https://cloudflared.bowring.uk/binaries/cloudflared-freebsd-latest.7z && 7z x cloudflared-freebsd-latest.7z && rm cloudflared-freebsd-latest.7z && mv -f ./temp/* ./cloudflared && rm -rf temp && chmod +x cloudflared
}

run() {
  if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
    if [[ "$ARGO_AUTH" =~ TunnelSecret ]]; then
      echo "$ARGO_AUTH" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > tunnel.json
      cat > tunnel.yml << EOF
tunnel: $(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "$ARGO_AUTH")
credentials-file: /app/tunnel.json
protocol: http2

ingress:
  - hostname: $ARGO_DOMAIN
    service: http://localhost:11443
EOF
      cat >> tunnel.yml << EOF
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
      nohup ./cloudflared tunnel --edge-ip-version auto --config tunnel.yml run 2>/dev/null 2>&1 &
    elif [[ "$ARGO_AUTH" =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
      nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 run --token  2>/dev/null 2>&1 &
    fi
  else
    nohup ./cloudflared tunnel --edge-ip-version auto --protocol http2 --no-autoupdate --url http://localhost:11443 2>/dev/null 2>&1 &
    sleep 12
    #local LOCALHOST=$(sockstat -4 -l -P tcp | grep cloudflare | awk '{print $6}')
    ARGO_DOMAIN=$(wget -qO- $(sockstat -4 -l -P tcp | grep cloudflare | awk '{print $6}')/quicktunnel | jq -r '.hostname')
		echo "ARGO_DOMAIN:"
  fi
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-k0baya-Vmess\", \"add\": \"alejandracaiccedo.com\", \"port\": \"443\", \"id\": \"1aa4f199-00f3-4916-8d75-0e49900e567d\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${ARGO_DOMAIN}\", \"path\": \"/serv00-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"${ARGO_DOMAIN}\", \"alpn\": \"\" }"
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

check_file
run
export_list

#!/bin/bash

# 端口参数 （必填）
WEBPORT=$(jq -r ".WEBPORT" vmess.json)
VMPORT=$(jq -r ".VMPORT" vmess.json)
export WEBPORT=$WEBPORT
export VMPORT=$VMPORT

# web.js 参数 （必填）
UUID=$(jq -r ".UUID" vmess.json)
WSPATH=$(jq -r ".WSPATH" vmess.json)

export UUID=$UUID
export WSPATH=$WSPATH

# ARGO 隧道参数（如需固定 ARGO 隧道，请把 ey 开头的 ARGO 隧道的 token 填入 ARGO_AUTH ，仅支持这一种方式固定，隧道域名代理的协议为 HTTP ，端口为 VMPORT 同端口。如果不固定 ARGO 隧道，请删掉ARGO_DOMAIN那行，保留ARGO_AUTH这行。）
ARGO_AUTH=$(jq -r ".ARGO_AUTH" vmess.json)
ARGO_DOMAIN=$(jq -r ".ARGO_DOMAIN" vmess.json)
export ARGO_AUTH=$ARGO_AUTH
if [ ! -z $ARGO_DOMAIN ]; then
	export ARGO_DOMAIN=$ARGO_DOMAIN
fi

# 网页的用户名和密码（可不填，默认为 admin 和 password ，如果不填请删掉这两行）dd
#WEB_USERNAME=$(jq -r ".WEB_USERNAME" vmess.json)
#WEB_PASSWORD=$(jq -r ".WEB_PASSWORD" vmess.json)
#export WEB_USERNAME=$WEB_USERNAME
#export WEB_PASSWORD=$WEB_PASSWORD


# 启动程序
#npm install
#nohup node server.js > a.log 2>&1 &

chmod +x ./entrypoint.sh
./entrypoint.sh > /dev/null 2>&1
mkdir -p tmp && cd tmp && wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-freebsd-64.zip \
&& unzip Xray-freebsd-64.zip && cd .. && mv -f ./tmp/xray ./web.js && rm -rf tmp && chmod +x web.js
nohup ./web.js -c ./config.json  > /dev/null 2>&1 &



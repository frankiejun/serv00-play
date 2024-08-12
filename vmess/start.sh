#!/bin/bash

# 端口参数 （必填）
export WEBPORT=
export VMPORT=

# web.js 参数 （必填）
export UUID=
export WSPATH=serv00

# ARGO 隧道参数（如需固定 ARGO 隧道，请把 ey 开头的 ARGO 隧道的 token 填入 ARGO_AUTH ，仅支持这一种方式固定，隧道域名代理的协议为 HTTP ，端口为 VMPORT 同端口。如果不固定 ARGO 隧道，请删掉ARGO_DOMAIN那行，保留ARGO_AUTH这行。）
export ARGO_AUTH=''
#export ARGO_DOMAIN=

# 网页的用户名和密码（可不填，默认为 admin 和 password ，如果不填请删掉这两行）dd
export WEB_USERNAME=
export WEB_PASSWORD=

# 启动程序
npm install
nohup node server.js > a.log 2>&1 &

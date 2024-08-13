#!/bin/bash

# 安装 Node.js 依赖
npm install

UUID=$(jq -r ".UUID" vless.json)
echo "UUID:$UUID"
PORT=$(jq  ".PORT" vless.json)
echo "PORT:$PORT"

export UUID=$UUID
export PORT=$PORT
# 启动 Node.js 应用
nohup node app.js > ./a.log 2>&1 &


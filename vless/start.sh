#!/bin/bash

# 安装 Node.js 依赖
npm install

export UUID="069c70e7-77a0-4850-a7b1-9af1e0120782"
export PORT=18619
# 启动 Node.js 应用
screen -S mysession -dm node app.js

# 这里可以添加其他自定义的脚本命令

# 保持脚本可执行
chmod +x start.sh

#!/bin/bash

message_text=$1
#解析模式，可选HTML或Markdown
MODE='HTML'
#api接口
telegramBotToken=
telegramBotUserId=

URL="https://api.telegram.org/bot${telegramBotToken}/sendMessage"
if [[ -z ${telegramBotToken} ]]; then
  echo "未配置TG推送"
else
  res=$(timeout 20s curl -s -X POST $URL -d chat_id=${telegramBotUserId} -d parse_mode=${MODE} -d text="${message_text}")
  if [ $? == 124 ]; then
    echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG'
    exit 1
  fi
  resSuccess=$(echo "$res" | jq -r ".ok")
  if [[ $resSuccess = "true" ]]; then
    echo "TG推送成功"
  else
    echo "TG推送失败，请检查TG机器人token和ID"
  fi
fi

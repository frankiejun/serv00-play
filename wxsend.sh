#!/bin/bash

text=$1

sendKey=${WXSENDKEY}
title="msg_from_serv00-play"
URL="https://sctapi.ftqq.com/$sendKey.send?"

if [[ -z ${sendKey} ]]; then
  echo "未配置微信推送的sendKey,通过 https://sct.ftqq.com/r/13223 注册并登录server酱，取得sendKey"
else
  res=$(timeout 20s curl -s -X POST $URL -d title=${title} -d desp="${text}")
  if [ $? == 124 ]; then
    echo "发送消息超时"
    exit 1
  fi

  err=$(echo "$res" | jq -r ".data.error")
  if [ "$err" == "SUCCESS" ]; then
    echo "微信推送成功"
  else
    echo "微信推送失败, error:$err"
  fi
fi

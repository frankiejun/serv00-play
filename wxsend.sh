#!/bin/bash

text=$1

sendKey=${WXSENDKEY}
wx_push_url=${WXPUSH_URL}
wx_token=${WX_TOKEN}
title="msg_from_serv00-play"
URL="https://sctapi.ftqq.com/$sendKey.send?"

if [[ -z "$1" ]]; then
	echo "错误：未提供要发送的消息内容。"
	echo "用法: $0 \"你的消息\""
	exit 1
fi

if [[ -z "${wx_push_url}" ]]; then
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
else
	if [[ -z ${wx_token} ]]; then
		echo "未配置wxpush微信推送的wx_token,请参考https://github.com/frankiejun/wxpush 获取wx_token"
	else
		res=$(timeout 20s curl -s -X POST "${wx_push_url}" -H "Authorization: $wx_token" -H "Content-Type: application/json" -d "{\"token\":\"${wx_token}\",\"title\":\"${title}\",\"content\":\"${text}\",\"contentType\":1,\"uids\":[],\"topicIds\":[]}")
		if [ $? == 124 ]; then
			echo "发送消息超时"
			exit 1
		fi

		if echo "$res" | grep -q "Successfully"; then
			echo "微信推送成功"
		else
			echo "微信推送失败, res:$res"
		fi
	fi
fi

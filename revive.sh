#!/bin/bash

AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
WXPUSH_URL=${WXPUSH_URL:-null}
WX_TOKEN=${WX_TOKEN:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL

PROXY_HOST=${PROXY_HOST:-null}
PROXY_PORT=${PROXY_PORT:-null}
PROXY_USER=${PROXY_USER:-null}
PROXY_PASS=${PROXY_PASS:-null}

export SOCKS5_USER="$PROXY_USER"
export SOCKS5_PASSWD="$PROXY_PASS"
# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""
for info in "${hosts_info[@]}"; do
	user=$(echo $info | jq -r ".username")
	host=$(echo $info | jq -r ".host")
	port=$(echo $info | jq -r ".port")
	pass=$(echo $info | jq -r ".password")

	if [[ "$AUTOUPDATE" == "Y" ]]; then
		script="/home/$user/serv00-play/keepalive.sh autoupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\" \"${WXPUSH_URL}\" \"${WX_TOKEN}\""
	else
		script="/home/$user/serv00-play/keepalive.sh noupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\" \"${WXPUSH_URL}\" \"${WX_TOKEN}\""
	fi
  #使用socks5代理进行登录
	if [[ "$PROXY_HOST" != "null" ]]; then
		output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand="connect -S ${PROXY_HOST}:${PROXY_PORT} %h %p" -p "$port" "$user@$host" "bash -s" <<<"$script")
	else
		output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" "bash -s" <<<"$script")
	fi

	echo "output:$output"

	if echo "$output" | grep -q "keepalive.sh"; then
		echo "登录成功"
		msg="🟢主机 ${host}, 用户 ${user}， 登录成功!\n"
	else
		echo "登录失败"
		msg="🔴主机 ${host}, 用户 ${user}， 登录失败!\n"
		chmod +x ./tgsend.sh
		export PASS=$pass
		./tgsend.sh "Host:$host, user:$user, 登录失败，请检查!"
	fi
	summary=$summary$(echo -n $msg)
done

if [[ "$LOGININFO" == "Y" ]]; then
	chmod +x ./tgsend.sh
	./tgsend.sh "$summary"
fi

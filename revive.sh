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
LOGINONCE=${LOGINONCE:-N}
export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL WXSENDKEY WXPUSH_URL WX_TOKEN

PROXY_HOST=${PROXY_HOST:-null}
PROXY_PORT=${PROXY_PORT:-null}
PROXY_USER=${PROXY_USER:-null}
PROXY_PASS=${PROXY_PASS:-null}

export SOCKS5_USER="$PROXY_USER"
export SOCKS5_PASSWD="$PROXY_PASS"

sendMsg() {
	local msg="$1"
	chmod +x ./tgsend.sh ./wxsend.sh
	if [ -n "$msg" ]; then
		if [ "$SENDTYPE" == "1" ]; then
			./tgsend.sh "$msg"
		elif [ "$SENDTYPE" == "2" ]; then
			./wxsend.sh "$msg"
		elif [ "$SENDTYPE" == "3" ]; then
			./tgsend.sh "$msg"
			./wxsend.sh "$msg"
		fi
	fi
}

# 登录服务器并执行保活脚本
login_server() {
	local user=$1
	local host=$2
	local port=$3
	local pass=$4
	local msg=""

	if [[ "$AUTOUPDATE" == "Y" ]]; then
		script="bash /home/$user/serv00-play/keepalive.sh autoupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\" \"${WXPUSH_URL}\" \"${WX_TOKEN}\""
	else
		script="bash /home/$user/serv00-play/keepalive.sh noupdate ${SENDTYPE} \"${TELEGRAM_TOKEN}\" \"${TELEGRAM_USERID}\" \"${WXSENDKEY}\" \"${BUTTON_URL}\" \"${pass}\" \"${WXPUSH_URL}\" \"${WX_TOKEN}\""
	fi
	#使用socks5代理进行登录
	if [[ "$PROXY_HOST" != "null" ]]; then
		echo "测试基础连接..." >&2
		if timeout 5 nc -zv "$PROXY_HOST" "$PROXY_PORT" &>/dev/null; then
			echo "✓ 可以连接到代理服务器" >&2
		else
			echo "✗ 无法连接到代理服务器" >&2
			exit 1
		fi
		output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ProxyCommand="connect -S ${PROXY_HOST}:${PROXY_PORT} %h %p" -p "$port" "$user@$host" "bash -s" <<<"$script")
	else
		output=$(sshpass -p "$pass" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$host" "bash -s" <<<"$script")
	fi

	#echo "output:$output" >&2

	if echo "$output" | grep -q "keepalive.sh"; then
		echo "登录成功" >&2
		msg="🟢主机 ${host}, 用户 ${user}， 登录成功!\n"
	else
		echo "登录失败" >&2
		msg="🔴主机 ${host}, 用户 ${user}， 登录失败!\n"
		export PASS=$pass
		sendMsg "Host:$host, user:$user, 登录失败，请检查!"
	fi
	echo -n "$msg"
}

summary=""
if [[ "$LOGINONCE" == "Y" ]]; then
	echo "只登录一次模式"
	# 计算今天是今年的第几天（1-366）
	DAY_OF_YEAR=$(date +%j)

	# 获取服务器数量
	SERVER_COUNT=$(echo "$HOSTS_JSON" | jq '.info | length')

	# 计算今天应该登录哪个服务器（取模运算）
	INDEX=$(((DAY_OF_YEAR - 1) % SERVER_COUNT))

	# 获取对应的服务器配置
	CONFIG=$(echo "$HOSTS_JSON" | jq ".info[$INDEX]")

	HOST=$(echo "$CONFIG" | jq -r '.host')
	USERNAME=$(echo "$CONFIG" | jq -r '.username')
	PORT=$(echo "$CONFIG" | jq -r '.port')
	PASSWORD=$(echo "$CONFIG" | jq -r '.password')

	summary=$(login_server "$USERNAME" "$HOST" "$PORT" "$PASSWORD")
else
	mapfile -t hosts_info < <(echo "${HOSTS_JSON}" | jq -c ".info[]")
	for info in "${hosts_info[@]}"; do
		user=$(echo "$info" | jq -r ".username")
		host=$(echo "$info" | jq -r ".host")
		port=$(echo "$info" | jq -r ".port")
		pass=$(echo "$info" | jq -r ".password")

		summary=$summary$(login_server "$user" "$host" "$port" "$pass")
	done
fi

if [[ "$LOGININFO" == "Y" ]]; then
	sendMsg "$summary"
fi

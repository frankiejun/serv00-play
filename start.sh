#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

installpath="$HOME"
art_wrod=$(figlet "serv00-play")
echo "<------------------------------------------------------------------>"
echo -e "${CYAN}${art_wrod}${RESET}"
echo -e "${GREEN} 饭奇骏频道:https://www.youtube.com/@frankiejun8965 ${RESET}"
echo -e "${GREEN} TG交流群:https://t.me/fanyousuiqun ${RESET}"
echo "<------------------------------------------------------------------>"

install(){
	cd 
	if [ -d serv00-play ]; then
		echo -e "${RED}请勿重复安装!${RESET}"
		exit 1
  fi
	echo "正在安装..."
	if ! git clone https://github.com/frankiejun/serv00-play.git; then
		echo -e "${RED}安装失败!${RESET}"
		exit 1;
  fi
	echo -e "${YELLOW}安装成功${RESET}"
}

checkvlessAlive(){
	if  ps  aux | grep app.js | grep -v "grep" ; then
		return 0
  else 
		return 1
	fi	
}

checkvmessAlive(){
	local c=0
	if ps  aux | grep web.js | grep -v "grep" > /dev/null ; then
		((c+1))
	fi

	if ps aux | grep cloud | grep -v "grep" > /dev/null ; then
		((c+1))
	fi	
	if ps aux | grep server.js | grep -v "grep" > /dev/null ; then
		((c+1))
	fi	

	echo "c=$c"
	if [ $c -eq 3 ]; then
		return 0
	fi

	return 1 # 有一个或多个进程不在运行

}

startVless(){
	cd ${installpath}/serv00-play/vless
	
	if checkvlessAlive; then
		echo -e "${RED}vless 已在运行，请勿重复操作!${RESET}"
		exit 1
	fi

	if ! ./start.sh; then
		echo e "${RED}vless启动失败！${RESET}"
		exit 1
	fi

	echo -e "${YELLOW}启动成功!${RESET}"

}

startVmess(){
	cd ${installpath}/serv00-play/vmess
	
	if checkvmessAlive; then
		echo -e "$RED}vmess 已在运行，请勿重复操作!${RESET}"
		exit 1
	else
		chmod 755 ./killvmess.sh
		./killvmess.sh
	fi

	if ! ./start.sh; then
		echo "vmess启动失败！"
		exit 1
	fi

	echo -e "${YELLOW}启动成功!${RESET}"

}

stopVless(){
	r=$(ps aux | grep app.js | grep -v "grep" | awk '{print $2}' ) 
	if [ -z "$r" ]; then
		echo "没有运行!"
		return 
	else	
		kill -9 $r
	fi
	echo "已停掉vless!"
}

stopVmess(){
	cd ${installpath}/serv00-play/vmess
	if [ -f killvmess.sh ]; then
		chmod 755 ./killvmess.sh
		./killvmess.sh
	else
		echo "请先安装serv00-play!!!"
		return 
	fi
	echo "已停掉vmess!"
}

createVlesConfig(){

			read -p "请输入UUID:" uuid
			read -p "请输入PORT:" port

			cat > vless.json <<EOF
			{
				"UUID":"$uuid",
				"PORT":$port

			}
EOF
}

configVless(){
	cd ${installpath}/serv00-play/vless
	
	if [ -f "vless.json" ]; then
		echo "配置文件内容:"
		 cat vless.json
    read -p "配置文件已存在，是否还要重新配置 (y/n) [y]?" input
		input=${input:-y}
		if [ "$input" != "y" ]; then
			return
		else
		 createVlesConfig
    fi
  else
     createVlesConfig
  fi
		echo -e "${YELLOW} vless配置完毕! ${RESET}"
	
}

createVmesConfig(){
   read -p "请输入web管理端口:" webport
   read -p "请输入vmess代理端口:" vmport
   read -p "请输入uuid:" uuid
   read -p "请输入WSPATH,默认是[serv00]" wspath
   wspath=${wspath:-serv00}

   read -p "请输入ARGO隧道token，如果没有按回车跳过:" token
   read -p "请输入ARGO隧道的域名，如果没有按回车跳过:" domain

   read -p "请输入管理网页的登录用户名[默认为 admin ]:" web_username
   web_username=${web_username:-admin}
   read -p "请输入管理页面的登录密码[默认为 password]:" web_pass
   web_pass=${web_pass:-password}

  cat > vmess.json <<EOF
  {
     "WEBPORT": $webport,
     "VMPORT": $vmport,
     "UUID": "$uuid",
     "WSPATH": "$wspath",
     "ARGO_AUTH": ${token:-null},
     "ARGO_DOMAIN": ${domain:-null},
     "WEB_USERNAME": "$web_username",
     "WEB_PASSWORD": "$web_pass"
  }

EOF
   echo -e "${YELLOW} vmess配置完毕! ${RESET}"


}

configVmess(){
	cd ${installpath}/serv00-play/vmess

	if [ -f ./vmess.json ]; then
		echo "配置文件内容:"
    cat ./vmess.json
    read -p "配置文件已存在，是否还要重新配置 (y/n) [y]?" input
		input=${input:-y}
		if [ "$input" != "y" ]; then
			return
		else
		 createVmesConfig
    fi
  else
     createVmesConfig
  fi

}

showVlessInfo(){
	user=$(whoami)
	domain=${user}".serv00.net"
	
	cd ${installpath}/serv00-play/vless
	if [ ! -f vless.json ]; then
		echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
		return 
	fi
	uuid=$(jq -r ".UUID" vless.json)
	port=$(jq -r ".PORT" vless.json)
	url="vless://${uuid}@${domain}:${port}?encryption=none&security=none&sni=${domain}&allowInsecure=1&type=ws&host=${domain}&path=%2F#serv00-vless"
	echo "v2ray:"
	echo -e "${GREEN}   $url ${RESET}"
}

showVmessInfo(){
	cd ${installpath}/serv00-play/vmess

	if [ ! -f vmess.json ]; then
      echo -e "${RED} 配置文件不存在，请先行配置! ${RESET}"
	    return
	fi
	chmod +x ./list.sh && ./list.sh main
}

createConfigFile(){
	echo "请选择要保活的项目:"
	echo "1. vless "
	echo "2. vmess "
	echo "3. 以上皆是 "
	read -p "请选择:" num
	item=()

	if [ "$num" = "1" ]; then
		item+=("vless")
	elif [ "$num" = "2" ]; then
		item+=("vmess")
	elif [ "$num" = "3" ];then
		item+=("vless")
		item+=("vmess")
	else
		echo "无效选择"
		return 
	fi

	cd ${installpath}/serv00-play/
	json_content='{"item":['
	for item in "${item[@]}"; do
		json_content+="\"$item\","
	done
	json_content="${json_content%,}]}"

}

setConfig(){
	cd ${installpath}/serv00-play/

	if [ -f config.json ]; then
		echo "目前已有配置:"
		cat config.json
		read -p "是否修改? [y/n] [y]" input
		if [ "$input" != "y" ]; then
			return
		fi
	fi
	createConfigFile
}

echo "请选择一个选项:"

options=("安装serv00-play项目" "运行vless" "运行vmess" "停止vless" "停止vmess"  "配置vless" "配置vmess" "显示vless的节点信息" "显示vmess的订阅链接" "置保活的项目" "退出")

select opt in "${options[@]}"
do
    case $opt in
        "安装serv00-play项目")
					  install
            ;;
        "运行vless")
				    read -p "请确认${installpath}/serv00-play/vless/vless.json 已配置完毕 (y/n) [y]?" input
						input=${input:-y}
						if [ "$input" != "y" ]; then
							echo "请先进行配置!!!"
							exit 1
						fi
            startVless
            ;;
        "运行vmess")
				    read -p "请确认${installpath}/serv00-play/vmess/vmess.json 已配置完毕 (y/n) [y]?" input
						input=${input:-y}
						if [ "$input" != "y" ]; then
							echo "请先进行配置!!!"
							exit 1
						fi
						startVmess
            ;;
        "停止vless")
            stopVless
            ;;
        "停止vmess")
            stopVmess
            ;;
			  "配置vless")
				    configVless
						;;
			  "配置vmess")
				    configVmess
						;;
				"显示vless的节点信息")
				    showVlessInfo
						;;
				"显示vmess的订阅链接")
						showVmessInfo
						;;
			  "设置保活的项目")
				   setConfig
					 ;;
        "退出")
            echo "退出"
            break
            ;;
        *) 
            echo "无效的选项 "
            ;;
    esac
done

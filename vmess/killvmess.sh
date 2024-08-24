#r=$(ps aux | grep server.js | grep -v grep | awk '{print $2}' )
#
#if [ -z "$r" ];then
#	echo "can't find server.js"
#else
#	echo "kill -9 $r"
#	kill -9 $r
#fi



r=$(ps aux | grep cloud | grep -v grep | awk '{print $2}' )

if [ -z "$r" ];then
	echo "can't find cloudflare"
else
	echo $r
	kill -9 $r
fi


r=$(ps aux | grep web.js | grep -v grep | awk '{print $2}' )

if [ -z "$r" ];then
	echo "can't find web.js"
else
	echo $r
	kill -9 $r
fi

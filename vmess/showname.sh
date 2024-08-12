wget -qO- $(sockstat -4 -l -P tcp | grep cloudflare | awk '{print $6}')/quicktunnel | jq -r '.hostname'

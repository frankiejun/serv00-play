wget -qO- $(sockstat -4 -l -P tcp | grep cloudflare | awk '{for(i=1;i<=NF;i++) if($i ~ /127\.0\.0\.1/) print $i}')/quicktunnel | jq -r '.hostname'

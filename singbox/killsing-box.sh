#!/bin/bash

# 定义需要检查和终止的进程名
processes=("cloudflare" "serv00sb")

for process in "${processes[@]}"; do
  # 查找进程 ID
  pids=$(ps aux | grep "$process" | grep -v grep | awk '{print $2}')

  if [ -z "$pids" ]; then
    echo "No process found: $process"
  else
    echo "Killing process: $process (PIDs: $pids)"
    # 逐个杀死进程
    for pid in $pids; do
      kill -9 "$pid"
    done
  fi
done

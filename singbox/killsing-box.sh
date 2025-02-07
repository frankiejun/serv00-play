#!/bin/bash

# 定义需要检查和终止的进程名
processes=("cloudflare" "serv00sb")

for process in "${processes[@]}"; do
  # 查找进程 ID
  pids=$(pgrep "$process")

  if [ -n "$pids" ]; then
    echo "Killing process: $process (PIDs: $pids)"
    # 逐个杀死进程
    for pid in $pids; do
      kill -9 "$pid"
    done
  fi
done

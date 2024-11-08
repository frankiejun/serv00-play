#!/usr/bin/expect -f

set timeout 10

# 获取参数
set REMOTE_USER [lindex $argv 0]
set REMOTE_HOST [lindex $argv 1]
set REMOTE_PORT [lindex $argv 2]
set REMOTE_PASSWORD [lindex $argv 3]
set REMOTE_SCRIPT [lindex $argv 4]

# SSH 登录并执行远程脚本
spawn ssh -o StrictHostKeyChecking=no -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST "bash -s" < $REMOTE_SCRIPT
expect {
      "yes/no" { send "yes\r"; exp_continue }
      "Password" { send "$REMOTE_PASSWORD\r" }
}
expect eof


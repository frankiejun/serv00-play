# serv00 上的一些应用，包括vless、vmess等, 自动化部署、批量保号、进程防杀、消息推送

## 前置工作

1. 你需要有一个 serv00 帐号
2. 预留了 1~3 个端口，vless+vmess 一共需要 3 个端口，vless 1 个，vmess 2 个，按实际情况使用。
3. serv00 管理面板 Run your own applications 已设置为 Enable

## 安装说明

```s
bash <(curl -Ls https://raw.githubusercontent.com/frankiejun/serv00-play/main/start.sh)
```

## 变量说明

| 变量名          | 示例   | 备注                                     |
| --------------- | ------ | ---------------------------------------- |
| HOSTS_JSON      | 见示例 | 可存放 n 个服务器信息                    |
| TELEGRAM_TOKEN  | 略     | telegram 机器人的 token                  |
| TELEGRAM_USERID | 略     | 待通知的 teltegram 用户 ID               |
| WXSENDKEY       | 略     | server 酱的 sendkey，用于接收微信消息    |
| SENDTYPE        | 3      | 选择推送方式，1.Telegram, 2.微信, 3.都有 |

## 消息推送

支持向 Telegram 和微信用户发送通知  

关于如何配置 Telegram 以实现消息推送，可以看 [这个视频](https://www.youtube.com/watch?v=l8fPnMfq86c&t=3s)

关于微信的配置，目前使用第三方平台提供的功能，可以到 [这里](https://sct.ftqq.com/r/13223) 注册并登录 server 酱，取得 sendKey

## HOSTS_JSON 的配置实例

```js
 {
   "info": [
    {
      "host": "s2.serv00.com",
      "username": "kkk",
      "port": 22,
      "password": "fdsafjijgn"
    },
    {
      "host": "s2.serv00.com",
      "username": "bbb",
      "port": 22,
      "password": "fafwwwwazcs"
    }
  ]
}
```

## 安装说明视频

[这里](https://youtu.be/1N7SGqBWooY)

## 项目鸣谢

本项目基于以下项目做的集成，少量的代码优化  
感谢原作者的开源贡献。  

vless 项目来自于： https://github.com/qwer-search/serv00-vless

vmess 项目来自于： https://github.com/k0baya/X-for-serv00.git

## 免责声明

本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。

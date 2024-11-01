启动服务的默认第一次密码是:  fkjyyds666



# serv00 上的一些应用，包括 vless/argo+vmess/vmess+ws/hy2/socks5/mtproto/alist/哪吒探针 等, 自动化部署、批量保号、进程防杀、消息推送

💖 如果你在用这个项目，请给我打个 star，好让我知道有多少人从这个项目中受益。

## 前置工作

1. 你需要有一个 serv00 帐号
2. 无需使用面板，安装 serv00-play 后，按 13 即可

## 安装说明

```s
bash <(curl -Ls https://raw.githubusercontent.com/frankiejun/serv00-play/main/start.sh)
```

## 变量说明

| 变量名              | 示例   | 备注                                     |
| ------------------- | ------ | ---------------------------------------- |
| HOSTS_JSON          | 见示例 | 可存放 n 个服务器信息                    |
| ~~TELEGRAM_TOKEN~~  | 略     | telegram 机器人的 token ~~               |
| ~~TELEGRAM_USERID~~ | 略     | 待通知的 teltegram 用户 ID               |
| ~~WXSENDKEY~~       | 略     | server 酱的 sendkey，用于接收微信消息    |
| ~~SENDTYPE~~        | 3      | 选择推送方式，1.Telegram, 2.微信, 3.都有 |

PS. 保进程逻辑已挪到 serv00 上做，actions 只做保号，降低访问频率. github 上只需配置 HOSTS_JSON

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

安装使用说明及使用密码可以看[这里](https://youtu.be/bpYV8r85F-8)

临时隧道已失效，请使用固定隧道名，[如何申请固定隧道名](https://youtu.be/KyMvtWknu-k)

## 赞助

<left><details><summary><strong> [点击展开] 请作者喝杯咖啡 ~🧧</strong></summary>
_捐赠将是对我最大的支持，它将激励我持续的创新和创作。_

![](https://look.pics.cloudns.ch/img/%E6%AC%A7%E6%98%93%E8%B5%9E%E5%8A%A9%E7%A0%81.png)

- **USDT-TRC20:** `TUa2hLirmyq6tUPpfxHuMmWJExR91vHo5t`

</details></left>

## 项目鸣谢

[qwer-search](https://github.com/qwer-search) 、[k0baya](https://github.com/k0baya) 、[eooce](https://github.com/eooce)、[nrootconauto](https://github.com/nrootconauto/MrChrootBSD)

## 免责声明

本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 文字、数据及图片均有所属版权, 如转载须注明来源。
使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。

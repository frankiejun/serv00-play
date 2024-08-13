const username = process.env.WEB_USERNAME || "admin";
const password = process.env.WEB_PASSWORD || "password";
const port = process.env.WEBPORT || 11888;
const UUID = process.env.UUID || '1aa4f199-00f3-4916-8d75-0e49900e567d';
const express = require("express");
const fs = require('fs');
const app = express();
var exec = require("child_process").exec;
const { createProxyMiddleware } = require("http-proxy-middleware");
const auth = require("basic-auth");

function getFourthLine(filename, callback) {
    fs.readFile(filename, 'utf8', function(err, data) {
        if (err) {
            return callback(err);
        }
        const lines = data.split('\n');
        if (lines.length >= 4) {
            callback(null, lines[3]); 
        } else {
            callback(new Error('Subscribution does not have four lines.'));
        }
    });
}

app.get("/", function (req, res) {
  res.send("hello world");
});

// 设置路由
app.get(`/${UUID}/vm`, (req, res) => {
      exec(
        "chmod +x ./list.sh && ./list.sh &",
        function (err, stdout, stderr) {
          if (err) {
            console.log("list.sh 调用失败！" + err);
          } else {
            console.log("list.sh 调用成功");
          }
        }
      );
    getFourthLine('list', (err, sub) => {
        if (err) {
            return res.status(500).send('Error reading file.');
        }
        res.send(sub);
    });
});

// 页面访问密码
app.use((req, res, next) => {
  const user = auth(req);
  if (user && user.name === username && user.pass === password) {
    return next();
  }
  res.set("WWW-Authenticate", 'Basic realm="Node"');
  return res.status(401).send();
});

app.get("/status", function (req, res) {
  let cmdStr =
    "ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>获取系统进程表：\n" + stdout + "</pre>");
    }
  });
});

//获取节点数据
app.get("/list", function (req, res) {
  let cmdStr = "cat list";
  const sub = UUID
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      const fullUrl = `${req.protocol}://${req.get('host')}/${sub}/vm`;
      res.type("html").send("<pre>V2ray订阅地址：" + fullUrl + "\n\n节点数据：\n\n" + stdout + "</pre>");
    }
  });
});
  
// keepalive begin
//web保活
function keep_web_alive() {
  exec("pgrep -laf web.js", function (err, stdout, stderr) {
		console.log(process.cwd());
    // 1.查后台系统进程，保持唤醒
    if (stdout.includes("./web.js -c ./config.json")) {
      console.log("web 正在运行");
    } else {
      //web 未运行，命令行调起
      exec(
        "chmod +x ./web.js && ./web.js -c ./config.json >./out.log 2>&1 &",
        function (err, stdout, stderr) {
          if (err) {
            console.log("保活-调起web-命令行执行错误:" + err);
          } else {
            console.log("保活-调起web-命令行执行成功!");
          }
        }
      );
    }
		setTimeout(keep_web_alive, 10 * 1000);
  });
}
keep_web_alive();

//Argo保活
function keep_argo_alive() {
  exec("pgrep -laf cloudflared", function (err, stdout, stderr) {
    // 1.查后台系统进程，保持唤醒
    if (stdout.includes("./cloudflared tunnel")) {
      console.log("Argo 正在运行");
    } else {
      //Argo 未运行，命令行调起
      exec("bash ./argo.sh ", function (err, stdout, stderr) {
        if (err) {
          console.log("保活-调起Argo-命令行执行错误:" + err);
        } else {
          console.log("保活-调起Argo-命令行执行成功!");
        }
      });
    }
		setTimeout(keep_argo_alive, 30 * 1000);
  });
}
keep_argo_alive();

app.use(
  "/",
  createProxyMiddleware({
    changeOrigin: true, // 默认false，是否需要改变原始主机头为目标URL
    onProxyReq: function onProxyReq(proxyReq, req, res) {
           // 如果客户端请求被中止，则中止代理请求
        req.on('aborted', () => {
            proxyReq.abort();
            console.log('Client request aborted, proxy request terminated.');
        });
			},
     onProxyRes: (proxyRes, req, res) => {
        // 如果客户端响应被关闭，则中止代理响应
        res.on('close', () => {
            if (!res.headersSent) {
                proxyRes.destroy();
                console.log('Client response closed, proxy response terminated.');
            }
        });
    },
    onError: (err, req, res) => {
        // 在代理出错时处理错误
        console.error('Proxy encountered an error:', err);
        res.writeHead(500, {
            'Content-Type': 'text/plain',
        });
        res.end('Something went wrong while proxying the request.');
    },
    pathRewrite: {
      // 请求中去除/
      "^/": "/",
    },
    target: "http://127.0.0.1:${PORT1}/", // 需要跨域处理的请求地址
    ws: true, // 是否代理websockets
  })
);

function download_web(callback) {
  let cmdStr = "mkdir -p tmp && cd tmp && wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-freebsd-64.zip && unzip Xray-freebsd-64.zip && cd .. && mv -f ./tmp/xray ./web.js && rm -rf tmp && chmod +x web.js";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      console.log("初始化-下载web文件失败:" + err);
    } else {
      console.log("初始化-下载web文件成功!");
    }
  });
}

download_web((err) => {
  if (err) {
    console.log("初始化-下载web文件失败");
  }
  else {
    console.log("初始化-下载web文件成功");
  }
});

// 启动核心脚本运行web和argo
exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));

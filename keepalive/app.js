const express = require('express')
const fs = require('fs')
const path = require('path')
const { exec } = require('child_process')
const bodyParser = require('body-parser')
const { log } = require('console')
const app = express()

app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))
app.use('/static', express.static(path.join(__dirname, 'static')))
const user = require('child_process').execSync('whoami').toString().trim()
const serv00PlayDir = `/home/${user}/serv00-play`
const keepaliveScript = `${serv00PlayDir}/keepalive.sh`

// 读取配置文件
const configPath = path.join(__dirname, 'config.json')
let config = {}
if (fs.existsSync(configPath)) {
  config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
}

// 实现 loadConfig 方法
function loadConfig() {
  if (fs.existsSync(configPath)) {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'))
    logError('配置文件重新加载成功')
  } else {
    logError('配置文件不存在')
  }
}

// 监听配置文件变化
fs.watchFile(configPath, (curr, prev) => {
  if (curr.mtime !== prev.mtime) {
    logError('检测到配置文件变化, 重新加载配置')
    loadConfig()
  }
})

// 验证token
function validateToken(req, res, next) {
  const token = cleanAndDecode(req.query.token)
  if (!token || token !== config.token) {
    logError(`Token验证失败: ${token}`)
    return res.status(401).send('无授权不能访问!')
  }
  next()
}

// 修改日志函数，确保同步写入
function logError(message) {
  if (config.showlog !== 'Y') {
    return
  }
  try {
    const timestamp = new Date().toISOString()
    const logMessage = `[${timestamp}] ${message}\n`
    const logFile = path.join(__dirname, 'logs', 'debug.log')

    // 确保日志目录存在
    if (!fs.existsSync(path.dirname(logFile))) {
      fs.mkdirSync(path.dirname(logFile), { recursive: true })
    }

    // 同步写入日志
    fs.appendFileSync(logFile, logMessage)
    console.log(logMessage) // 同时输出到控制台
  } catch (error) {
    console.error('日志记录失败:', error)
  }
}
// 添加请求日志中间件
app.use((req, res, next) => {
  logError(`${req.method} ${req.url}`)
  next()
})

// 清理和解码函数
function cleanAndDecode(str) {
  if (!str || str === 'null') return 'null'
  try {
    return Buffer.from(str.trim(), 'base64')
      .toString('utf8')
      .replace(/[\s\uFEFF\xA0]/g, '')
  } catch (e) {
    logError(`Base64 decode error: ${e.message}`)
    return 'null'
  }
}

// 定时调用脚本的方法
function scheduleScript() {
  const cmd = `cd ${serv00PlayDir} && bash ${keepaliveScript} `

  const executeScript = () => {
    const interval = (parseInt(config.interval, 10) || 5) * 60000 // 默认5分钟

    logError(`定时执行脚本: ${cmd}, 间隔: ${interval}ms`)
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        logError(`定时执行脚本错误: ${error.message}`)
        logError(stderr)
      } else {
        logError('定时执行脚本成功')
        logError(stdout)
      }
    })

    // 设置定时器
    setTimeout(executeScript, interval)
  }

  // 立即执行一次
  executeScript()
}

// 启动定时任务
scheduleScript()

// 记录启动信息
logError('服务启动')
// 获取 autoupdate 状态
function getAutoupdateStatus(autoupdate) {
  return autoupdate === 'Y' ? 'autoupdate' : 'noupdate'
}

// 处理首页请求
app.get('/', (req, res) => {
  if (config.img) {
    res.send(`
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>首页</title>
        </head>
        <body style="margin:0; padding:0;">
          <img src="/static/${config.img}" alt="首页" style="max-width:100%; height:auto;">
        </body>
      </html>
    `)
  } else {
    res.send('Welcome')
  }
})

app.get('/keep', validateToken, async (req, res) => {
  logError('开始处理参数')
  // 处理参数
  logError('接收到的参数:')
  logError(`autoupdate: ${req.query.autoupdate}`)
  logError(`sendtype: ${req.query.sendtype}`)
  logError(`telegramtoken: ${req.query.telegramtoken}`)
  logError(`telegramuserid: ${req.query.telegramuserid}`)
  logError(`wxsendkey: ${req.query.wxsendkey}`)
  logError(`buttonurl: ${req.query.buttonurl}`)
  logError(`pass: ${req.query.pass}`)

  const params = {
    autoupdate: getAutoupdateStatus(req.query.autoupdate),
    sendtype: req.query.sendtype ? req.query.sendtype.trim() : 'null',
    telegramtoken: cleanAndDecode(req.query.telegramtoken),
    telegramuserid: req.query.telegramuserid
      ? req.query.telegramuserid.trim()
      : 'null',
    wxsendkey: cleanAndDecode(req.query.wxsendkey),
    buttonurl: cleanAndDecode(req.query.buttonurl),
    pass: cleanAndDecode(req.query.password),
  }

  logError(
    '处理参数: ' +
      JSON.stringify({
        ...params,
        pass: '***',
      })
  )
  // 本地执行
  logError('本地执行keepalive')
  const cmd = `cd ${serv00PlayDir} && nohup bash ${keepaliveScript} ${params.autoupdate} ${params.sendtype} ${params.telegramtoken} ${params.telegramuserid} ${params.wxsendkey} ${params.buttonurl} ${params.pass} > /dev/null 2>&1 &`
  logError('cmd:' + cmd)
  exec(cmd, (error) => {
    if (error) {
      logError(`本地执行错误: ${error}`)
    } else {
      logError('本地执行成功')
    }
  })
  res.send('ok')
})

app.listen(3000, () => {
  console.log('Server is running on port 3000')
})

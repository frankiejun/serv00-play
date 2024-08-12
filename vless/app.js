const net = require('net');
const WebSocket = require('ws');
const logcb = (...args) => console.log.bind(this, ...args);
const errcb = (...args) => console.error.bind(this, ...args);

const uuid = (process.env.UUID || '069c70e7-77a0-4850-a7b1-9af1e0120783').replace(/-/g, '');
const port = process.env.PORT || 18619;

const wss = new WebSocket.Server({ port }, logcb('listen:', port));

wss.on('connection', ws => {
    console.log("on connection");

    let duplex, targetConnection;

    const cleanup = () => {
        if (duplex) {
            duplex.destroy(); // 销毁 duplex 流以释放资源
        }
        if (targetConnection) {
            targetConnection.end(); // 结束与目标主机的连接
        }
        ws.terminate(); // 终止 WebSocket 连接
    };

    ws.once('message', msg => {
        const [VERSION] = msg;
        const id = msg.slice(1, 17);

        if (!id.every((v, i) => v === parseInt(uuid.substr(i * 2, 2), 16))) {
            ws.close();
            return;
        }

        let i = msg.slice(17, 18).readUInt8() + 19;
        const targetPort = msg.slice(i, i += 2).readUInt16BE(0);
        const ATYP = msg.slice(i, i += 1).readUInt8();
        const host = ATYP === 1 ? msg.slice(i, i += 4).join('.') : // IPV4
            (ATYP === 2 ? new TextDecoder().decode(msg.slice(i + 1, i += 1 + msg.slice(i, i + 1).readUInt8())) : // domain
                (ATYP === 3 ? msg.slice(i, i += 16).reduce((s, b, i, a) => (i % 2 ? s.concat(a.slice(i - 1, i + 1)) : s), []).map(b => b.readUInt16BE(0).toString(16)).join(':') : '')); // IPV6

        logcb('conn:', host, targetPort);

        ws.send(new Uint8Array([VERSION, 0]));

        duplex = WebSocket.createWebSocketStream(ws);

        targetConnection = net.connect({ host, port: targetPort }, function () {
            this.write(msg.slice(i));
            duplex.on('error', errcb('E1:')).pipe(this).on('error', errcb('E2:')).pipe(duplex);
        }).on('error', errcb('Conn-Err:', { host, port: targetPort }));

        targetConnection.on('close', cleanup); // 目标连接关闭时清理资源
    }).on('error', errcb('EE:'));

    ws.on('close', cleanup); // WebSocket 连接关闭时清理资源
});


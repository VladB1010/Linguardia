
const WebSocket = require('ws');
const http      = require('http');

const PORT = process.env.PORT || 8765;

const httpServer = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('LINGUARDIA Duel Server OK\n');
});

const wss = new WebSocket.Server({ server: httpServer });

const queue   = new Map();
const rooms   = new Map();
let nextId    = 0;

function uid() {
    return (++nextId).toString(36) + '_' + Date.now().toString(36);
}

function queueKey(lang, level) {
    return `${lang || 'en'}:${level || 'beginner'}`;
}

wss.on('connection', (ws, req) => {
    ws._id       = uid();
    ws._roomId   = null;
    ws._role     = null;
    ws._lang     = 'en';
    ws._level    = 'beginner';

    const ip = req.socket.remoteAddress;
    console.log(`[+] ${ws._id} connected from ${ip}`);

    ws.on('message', (raw) => {
        let msg;
        try { msg = JSON.parse(raw.toString()); }
        catch { return; }

        switch (msg.type) {

            case 'join_queue':
                ws._lang  = msg.language || 'en';
                ws._level = msg.level    || 'beginner';
                handleQueue(ws);
                break;

            case 'party_action':
            case 'action':
            case 'special_result':
            case 'defend_result':
            case 'chat':
                relay(ws, msg);
                break;

            case 'leave_queue': {
                const key = queueKey(ws._lang, ws._level);
                if (queue.get(key) === ws) queue.delete(key);
                break;
            }
        }
    });

    ws.on('close', () => {
        console.log(`[-] ${ws._id} disconnected`);

        const key = queueKey(ws._lang, ws._level);
        if (queue.get(key) === ws) queue.delete(key);

        if (ws._roomId && rooms.has(ws._roomId)) {
            const room     = rooms.get(ws._roomId);
            const opponent = room.p1 === ws ? room.p2 : room.p1;
            if (opponent && opponent.readyState === WebSocket.OPEN) {
                send(opponent, { type: 'opponent_disconnected' });
            }
            rooms.delete(ws._roomId);
        }
    });

    ws.on('error', (err) => console.error(`[!] ${ws._id} error: ${err.message}`));
});

function handleQueue(ws) {
    const key     = queueKey(ws._lang, ws._level);
    const waiting = queue.get(key);

    if (waiting && waiting !== ws && waiting.readyState === WebSocket.OPEN) {
        const roomId   = uid();
        waiting._roomId = roomId;
        ws._roomId      = roomId;
        waiting._role   = 'p1';
        ws._role        = 'p2';

        rooms.set(roomId, { p1: waiting, p2: ws });
        queue.delete(key);

        send(waiting, {
            type:    'matched',
            role:    'p1',
            room_id: roomId,
        });
        send(ws, {
            type:    'matched',
            role:    'p2',
            room_id: roomId,
        });

        console.log(`[~] Room ${roomId} [${key}]: ${waiting._id} vs ${ws._id}`);

    } else {
        queue.set(key, ws);
        send(ws, { type: 'waiting' });
        console.log(`[?] ${ws._id} waiting [${key}]…`);
    }
}

function relay(ws, msg) {
    if (!ws._roomId || !rooms.has(ws._roomId)) return;
    const room     = rooms.get(ws._roomId);
    const opponent = room.p1 === ws ? room.p2 : room.p1;
    if (opponent && opponent.readyState === WebSocket.OPEN) {
        send(opponent, { ...msg, from: ws._role });
    }
}

function send(ws, data) {
    if (ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify(data));
    }
}

httpServer.listen(PORT, () => {
    console.log(`LINGUARDIA Duel Server listening on port ${PORT}`);
});

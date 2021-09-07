'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const WebSocket = require("ws");
const http = require("http");
let logger = wl.init('NEP-notification-server');
function initializeServer(simulatorContext, wssPort) {
    logger.log('info', `Starting websocket server on port ${wssPort}`);
    const wss = new WebSocket.Server({ port: wssPort, server: new http.Server });
    wss.on('connection', function connection(ws) {
        logger.log('debug', `A new client has connected`);
        ws.on('message', function incoming(message) {
            logger.log('debug', `Incoming websocket message: ${message}`);
            const msg = JSON.parse(message.toString());
            const subscriptions = msg['subscriptions'];
            subscriptions.forEach(subscription => {
                const topicId = subscription['topicId']['name'];
                simulatorContext.addNotificationClient(topicId, ws);
            });
            if (!simulatorContext.isDummyMode()) {
                ws.send(`{"subscriptionsCreated": ${subscriptions.length}}`);
            }
            ;
        });
        ws.on('close', function closed() {
            simulatorContext.removeNotificationClient(ws);
        });
    });
    wss.on('listening', function listening(wss) {
        logger.log('info', `Websocket server is started on ${wssPort}`);
    });
}
exports.initializeServer = initializeServer;
//# sourceMappingURL=nep-notification-server.js.map
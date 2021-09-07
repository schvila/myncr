'use strict';

import * as wl from '@config/winston';
import * as WebSocket from 'ws';
import * as http from 'http';
import * as SimulatorContext from './simulator/Context'

let logger = wl.init('NEP-notification-server');

export function initializeServer (simulatorContext: SimulatorContext.Context, wssPort: number) {
    logger.log('info', `Starting websocket server on port ${wssPort}`);
    const wss: WebSocket.Server = new WebSocket.Server({ port: wssPort, server: new http.Server });

    wss.on('connection', function connection(ws) {
        logger.log('debug',`A new client has connected`);


        ws.on('message', function incoming(message) {
            logger.log('debug', `Incoming websocket message: ${message}`);
            const msg: object = JSON.parse(message.toString());

            const subscriptions: any[] = msg['subscriptions'];
            subscriptions.forEach(subscription => {
                const topicId: string = subscription['topicId']['name'];
                simulatorContext.addNotificationClient(topicId, ws);
            });

            if (!simulatorContext.isDummyMode()) {
                ws.send(`{"subscriptionsCreated": ${subscriptions.length}}`);
            };
        });

        ws.on('close', function closed() {
            simulatorContext.removeNotificationClient(ws);
        });
    });

    wss.on('listening', function listening(wss) {
        logger.log('info', `Websocket server is started on ${wssPort}`);
    });
}

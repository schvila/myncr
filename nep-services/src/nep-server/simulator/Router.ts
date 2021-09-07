'use strict';

import * as express from 'express';
import ItemAttributes = require('./../service/CatalogServiceComponents/ItemAttributes');
import itemPrices = require('./../service/CatalogServiceComponents/ItemPrices');
import {Context} from './../simulator/Context'
import * as wl from '@config/winston';

let logger = wl.init('Router');

export function initializeRoutes(app: any, server: any, context: Context) {
    app.route('/simulator/requests').get((request: express.Request, response: express.Response) => {
        response.json(context.getRequests());
    });

    app.route('/simulator/requests').delete((request: express.Request, response: express.Response) => {
        response.json(context.clearAllRequests());
    });

    app.route('/simulator/request').get((request: express.Request, response: express.Response) => {
        context.getNextRequest(20000).then((retrievedRequest) => {
            response.json(retrievedRequest);
        }).catch(() => {
            response.json(null);
        });
    });

    app.route('/simulator/requestcountwithproperties').post((request: express.Request, response: express.Response) => {
        context.getNextRequestWithPropertiesCount(20000, request.body.body, request.body.count)
            .then(result => response.json(result))
            .catch(() => response.json(false));
    });

    app.route('/simulator/response-action').post((request: express.Request, response: express.Response) => {
        context.storeResponseAction(request);
        response.end();
    });

    app.route('/simulator/response-action').delete((request: express.Request, response: express.Response) => {
        context.clearAllResponses();
        response.end();
    });

    app.route('/simulator/configuration').put((request: express.Request, response: express.Response) => {
        const result = context.setConfiguration(request.body);
        if (response == null){
            response.end();
        } else {
            response.json(result);
        }
    });

    app.route('/simulator/catalog/itemAttributes/Snapshots').delete((request: express.Request, response: express.Response) => {
        ItemAttributes.clearItemAttributes();
        response.end();
    });

    app.route('/simulator/catalog/itemPrices/Snapshots').delete((request: express.Request, response: express.Response) => {
        itemPrices.clearItemPrices();
        response.end();
    });


    app.route('/notifications/simulator/:topic/message').post((request: express.Request, response: express.Response) => {
        const topic: string = request.params['topic'];
        context.sendMessageToAllNotificationClients(topic, request.body);
        response.end();
    });

    app.route('/notifications/simulator/connections').delete((request: express.Request, response: express.Response) => {
        response.json(context.disconnectAllNotificationClients());
    });

    app.route('/simulator/shutdown').post((request: express.Request, response: express.Response) => {
        response.json({"shutdown" : true });
        server.close(() => { 
            logger.log('info', `Shutting down the simulator.`);
            logger.on('finish', () => { process.exit(); });          
            logger.end();
        });
    });
};

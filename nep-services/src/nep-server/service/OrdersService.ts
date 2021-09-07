'use strict';

import * as wl from '@config/winston';
import * as express from 'express';
import { skipIfDummyMode, checkServiceAPIVersionIsCorrect } from './ServiceCommon'
import {Context} from 'nep-server/simulator/Context';

interface IOdspOrder extends express.Request {id: string};

let orders: IOdspOrder[] = [];
let baseOrderId = new Date().getTime();

let logger = wl.init('OrderService');
let baseUrl = '/order/:version/orders/1';
let orderNotificationsTopic = 'order_change_3'
let orderVersion = 3;

function updateOrder(order: express.Request): void {
    let newDate = new Date().toISOString();
    logger.log('info',`Updating order date: from ${order['dateUpdated']} to ${newDate}`);
    order['dateUpdated'] = newDate;
    order['etag'] = order['dateUpdated'];
}

function sendOrderUpdatedNotification(order: express.Request, simulatorContext: Context): void {
    const payload = {
        "id": order['id'],
        "updatedOrder": order
    };

    simulatorContext.sendMessageToAllNotificationClients(orderNotificationsTopic, JSON.stringify(payload));
}

function createOrderNotFoundResponse(response: express.Response, orderId: string): void {
    logger.log('error', `Order was not found: ${orderId}`);
    response.status(404).json({
        "message": `The order specified by id ${orderId} was not found`,
        "errorType": 'com.ncr.pcr.sc.simulator.resourcenotfound',
        "details": ['The specified resource was not found']
    });
}

function findOrder(orderId: string): express.Request {
    let targetOrder: express.Request = null;
    orders.forEach((order: IOdspOrder) => {
        if (order.id === orderId) {
            targetOrder = order;
            return true;
        }
        return false;
    });

    return targetOrder;
}

function replaceOrder(order: any);
function replaceOrder(order) {
    for (let i = 0; i < orders.length; i++) {
        if (orders[i].id === order.id) {
            orders[i] = order;
        }
    }
}

function patchOrder(order: express.Request, patch: any): void {
    for (let key in patch) {
        if (key in order) {
            order[key] = patch[key]
        }
    }
}

export function initializeRoutes(app: any, simulatorContext: Context);
export function initializeRoutes(app, simulatorContext: Context) {
    app.post(baseUrl, skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Placing a new order');
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);
        const newOrder = req.body;

        const newOrderDateTime = new Date();
        newOrder['dateCreated'] = newOrderDateTime.toISOString();
        updateOrder(newOrder);

        newOrder['sourceOrganization'] = req.headers['nep-organization'];
        newOrder['enterpriseUnitId'] = req.headers['nep-enterprise-unit'];

        if (!('id' in newOrder)) {
            newOrder['id'] = baseOrderId.toString();
            baseOrderId++;
        } else {
            logger.log('debug', `A new order has predefined id ${newOrder['id']}`);
        }

        orders.push(newOrder);
        res.json(newOrder);

        sendOrderUpdatedNotification(newOrder, simulatorContext);
    });

    app.get(`${baseUrl}/find-unacknowledged`, skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Retrieving unacknowledged orders');
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);
        const unacknowledgedOrders: IOdspOrder[] = [];

        orders.forEach(order => {
            if (!('dateAcknowledged' in order)) {
                unacknowledgedOrders.push(order);
            }
        });

        res.json({
            "orders": unacknowledgedOrders,
            "totalResults": unacknowledgedOrders.length,
            "totalPages": 1,
            "pageNumber": 0,
            "lastPage": true
        });
    });

    app.post(`${baseUrl}/:orderId/acks`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Acknowledging order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);

        const order = findOrder(orderId);
        if (order != null) {
            order['dateAcknowledged'] = new Date().toISOString();
            res.json(order);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });

    app.get(`${baseUrl}/:orderId`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Retrieving order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);

        const order = findOrder(orderId);
        if (order != null) {
            res.json(order);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });

    app.post(`${baseUrl}/:orderId/lock`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Locking order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);


        const order = findOrder(orderId);
        if (order != null) {
            order['lock'] = {
                "lockedBy": req.headers['nr1-device-id'],
                "lockedDate": new Date().toISOString()
            };
            updateOrder(order);
            res.json(order);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });

    app.put(`${baseUrl}/:orderId`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Updating order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);

        const order = findOrder(orderId);
        if (order != null) {
            updateOrder(order);
            res.json(order);
            req.body['id'] = orderId;
            replaceOrder(req.body);

            sendOrderUpdatedNotification(order, simulatorContext);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });

    app.post(`${baseUrl}/:orderId/unlock`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Unlocking order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);

        const order = findOrder(orderId);
        if (order != null) {
            delete order['lock'];
            updateOrder(order);
            res.json(order);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });

    app.patch(`${baseUrl}/:orderId`, skipIfDummyMode(simulatorContext), (req, res) => {
        const orderId = req.params['orderId'];
        logger.log('info', `Patching order ${orderId}`);
        checkServiceAPIVersionIsCorrect(orderVersion, req.params['version'], res);
        const patch = req.body;
        logger.log('info', `Patch: ${JSON.stringify(patch)}`);
        const order = findOrder(orderId);
        if (order != null) {
            patchOrder(order, patch);
            updateOrder(order);
            res.json(order);
            sendOrderUpdatedNotification(order, simulatorContext);
        } else {
            createOrderNotFoundResponse(res, orderId);
        }
    });
};

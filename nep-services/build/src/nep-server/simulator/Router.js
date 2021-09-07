'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const ItemAttributes = require("./../service/CatalogServiceComponents/ItemAttributes");
const itemPrices = require("./../service/CatalogServiceComponents/ItemPrices");
const wl = require("@config/winston");
let logger = wl.init('Router');
function initializeRoutes(app, server, context) {
    app.route('/simulator/requests').get((request, response) => {
        response.json(context.getRequests());
    });
    app.route('/simulator/requests').delete((request, response) => {
        context.clearAllRequests();
        response.status(204).end();
    });
    app.route('/simulator/request').get((request, response) => {
        context.getNextRequest(20000).then((retrievedRequest) => {
            response.json(retrievedRequest);
        }).catch(() => {
            response.json(null);
        });
    });
    app.route('/simulator/requestcountwithproperties').post((request, response) => {
        context.getNextRequestWithPropertiesCount(20000, request.body.body, request.body.count)
            .then(result => response.json(result))
            .catch(() => response.json(false));
    });
    app.route('/simulator/response-action').post((request, response) => {
        context.storeResponseAction(request);
        response.status(204).end();
    });
    app.route('/simulator/response-action').delete((request, response) => {
        context.clearAllResponses();
        response.end();
    });
    app.route('/simulator/configuration').put((request, response) => {
        const result = context.setConfiguration(request.body);
        if (response == null) {
            response.end();
        }
        else {
            response.json(result);
        }
    });
    app.route('/simulator/catalog/itemAttributes/Snapshots').delete((request, response) => {
        ItemAttributes.clearItemAttributes();
        response.end();
    });
    app.route('/simulator/catalog/itemPrices/Snapshots').delete((request, response) => {
        itemPrices.clearItemPrices();
        response.end();
    });
    app.route('/notifications/simulator/:topic/message').post((request, response) => {
        const topic = request.params['topic'];
        context.sendMessageToAllNotificationClients(topic, request.body);
        response.end();
    });
    app.route('/notifications/simulator/connections').delete((request, response) => {
        response.json(context.disconnectAllNotificationClients());
    });
    app.route('/simulator/shutdown').post((request, response) => {
        response.json({ "shutdown": true });
        server.close(() => {
            logger.log('info', `Shutting down the simulator.`);
            logger.on('finish', () => { process.exit(); });
            logger.end();
        });
    });
}
exports.initializeRoutes = initializeRoutes;
;
//# sourceMappingURL=Router.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const express = require("express");
const morgan = require("morgan"); // Logging requests
const bodyParser = require("body-parser");
const typeis = require("type-is");
const orderService = require("./service/OrdersService");
const securityService = require("./service/SecurityService");
const itemAvailabilityService = require("./service/ItemAvailabilityService");
const catalogService = require("./service/CatalogService");
const storageService = require("./service/StorageService");
const provisioningService = require("./service/ProvisioningService");
const rcmServerService = require("./service/RCMServerService");
const promotionExecutionService = require("./service/PromotionExecutionService");
const unifiedLoyaltyPromotions = require("./service/UnifiedLoyaltyPromotion");
const posConnectService = require("./service/PosConnectService");
const router = require("./simulator/Router");
const swaggerUi = require("swagger-ui-express");
const swaggerJSDoc = require("swagger-jsdoc");
const openApiDef = require("./../openapi-def");
let logger = wl.init('NEP-server');
let app = express();
// Special cases without content-type
app.use((req, res, next) => {
    if (!('content-type' in req.headers)) {
        logger.log('debug', `Missing content-type header, trying to detect type`);
        if (/RadSOHTTPClientSvcs/.test(req.headers['user-agent'])) {
            req.headers['content-type'] = 'application/xml';
        }
        if (req.headers['content-type'] !== undefined) {
            logger.log('debug', `Detected ${req.headers['content-type']}`);
        }
        else {
            logger.log('warn', `Failed to detect content-type`);
        }
    }
    else {
        logger.log('debug', `Received ${req.headers['content-type']}`);
    }
    next();
});
app.use(bodyParser.raw({ limit: '50mb', type: 'binary/octet-stream' }));
app.use(bodyParser.json({ limit: '50mb', type: 'application/json' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000, type: 'application/x-www-form-urlencoding' }));
app.use(bodyParser.raw({ limit: '50mb', type: 'application/xml' }));
app.use(bodyParser.text({ limit: '50mb', type: 'text/plain' }));
app.use((req, res, next) => {
    if (typeis(req, ['application/xml'])) {
        logger.log('debug', `Setting raw text content as body`);
        req.body = req.body.toString();
    }
    next();
});
app.use(morgan('combined', { stream: logger.stream })); // Log requests automatically
app.route('/state').get(function (request, response) {
    response.json({ 'Status': true });
});
const options = {
    definition: openApiDef,
    apis: ['./src/nep-server/service/RCMServerService.ts', './src/nep-server/service/PromotionExecutionService.ts'],
};
const swaggerSpec = swaggerJSDoc(options);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
function initializeServer(simulatorContext, serverPort) {
    app.use((req, res, next) => {
        logger.log('debug', `Incoming url: ${req.url}`);
        next();
    });
    let server = app.listen(serverPort);
    // initialize simulator's server
    router.initializeRoutes(app, server, simulatorContext);
    // store requests
    app.use((req, res, next) => {
        if (!/\/simulator\//.exec(req.path)) {
            simulatorContext.addRequest(req);
        }
        next();
    });
    app.use((req, res, next) => {
        if (!simulatorContext.handleRequest(req, res)) {
            next();
        }
    });
    securityService.initializeRoutes(app, simulatorContext);
    orderService.initializeRoutes(app, simulatorContext);
    itemAvailabilityService.initializeRoutes(app, simulatorContext);
    catalogService.initializeRoutes(app, simulatorContext);
    storageService.initializeRoutes(app, simulatorContext);
    provisioningService.initializeRoutes(app, simulatorContext);
    rcmServerService.initializeRoutes(app, simulatorContext);
    promotionExecutionService.initializeRoutes(app, simulatorContext);
    unifiedLoyaltyPromotions.initializeRoutes(app, simulatorContext);
    posConnectService.initializeRoutes(app, simulatorContext);
    app.use((req, res) => {
        res.status(400).json({
            "message": 'Failed to process request',
            "errorType": 'com.ncr.pcr.sc.simulator.makerequestfailexception',
            "details": ['Request intentionally failed']
        });
        logger.log('error', `API not supported: ${req.originalUrl}`);
    });
    app.use((err, req, res) => {
        logger.log('error', err.stack);
        res.status(500).send(`Something broke! ${err.details}`);
    });
    logger.log('info', `NEP Server started on ${serverPort}`);
}
exports.initializeServer = initializeServer;
;
//# sourceMappingURL=nep-server.js.map
'use strict';

import * as wl from '@config/winston';
import * as express from 'express';
import * as morgan from 'morgan'; // Logging requests
import * as bodyParser from 'body-parser';
import * as typeis from 'type-is';

import * as orderService from './service/OrdersService';
import * as securityService from './service/SecurityService';
import * as itemAvailabilityService from './service/ItemAvailabilityService';
import * as catalogService from './service/CatalogService';
import * as storageService from './service/StorageService';
import * as provisioningService from './service/ProvisioningService';
import * as rcmServerService from './service/RCMServerService';
import * as promotionExecutionService from './service/PromotionExecutionService';
import {Context} from './simulator/Context'
import * as router from './simulator/Router';

import * as swaggerUi from 'swagger-ui-express';
import * as  swaggerJSDoc from 'swagger-jsdoc';
import * as openApiDef from './../openapi-def';

let logger = wl.init('NEP-server');
let app = express();

// Special cases without content-type
app.use((req: express.Request, res: express.Response, next: express.NextFunction): void => {
    if (!('content-type' in req.headers)) {
        logger.log('debug', `Missing content-type header, trying to detect type`);
        if (/RadSOHTTPClientSvcs/.test(req.headers['user-agent'])) {
            req.headers['content-type'] = 'application/xml';
        }

        if (req.headers['content-type'] !== undefined) {
            logger.log('debug', `Detected ${req.headers['content-type']}`);
        } else {
            logger.log('warning', `Failed to detect content-type`);
        }
    }

    next();
});


app.use(bodyParser.raw({ limit: '50mb', type: 'binary/octet-stream' }));
app.use(bodyParser.json({ limit: '50mb', type: 'application/json' }));
app.use(bodyParser.urlencoded({ limit: '50mb', extended: true, parameterLimit: 50000, type: 'application/x-www-form-urlencoding' }));
app.use(bodyParser.raw({ limit: '50mb', type: 'application/xml' }));

app.use((req: express.Request, res: express.Response, next: express.NextFunction): void => {
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
    apis: ['./src/nep-server/service/RCMServerService.ts','./src/nep-server/service/PromotionExecutionService.ts'],
  };

const swaggerSpec = swaggerJSDoc(options);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

export function initializeServer(simulatorContext: Context, serverPort: number): void {
    app.use((req: express.Request, res: express.Response, next: express.NextFunction): void => {
        logger.log('debug', `Incoming url: ${req.url}`);
        next();
    });

    let server = app.listen(serverPort);

    // initialize simulator's server
    router.initializeRoutes(app, server, simulatorContext);

    // store requests
    app.use((req: express.Request, res: express.Response, next: express.NextFunction): void => {
        if (!/\/simulator\//.exec(req.path)) {
            simulatorContext.addRequest(req);
        }
        next();
    });

    app.use((req: express.Request, res: express.Response, next: express.NextFunction): void => {
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

    app.use((req: express.Request, res: express.Response): void => {
        res.status(400).json({
            "message": 'Failed to process request',
            "errorType": 'com.ncr.pcr.sc.simulator.makerequestfailexception',
            "details": ['Request intentionally failed']
        });
        logger.log('error', `API not supported: ${req.originalUrl}`);
    });

    app.use((err: any, req: express.Request, res: express.Response): void => {
        logger.log('error', err.stack);
        res.status(500).send(`Something broke! ${err.details}`);
    });

    logger.log('info', `NEP Server started on ${serverPort}`);
};
    
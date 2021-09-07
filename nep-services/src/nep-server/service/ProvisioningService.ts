'use strict';

import * as wl from '@config/winston';
import * as express from 'express';

let logger = wl.init('ProvisioningService');

export function initializeRoutes(app, simulatorContext) {
    app.post('/provisioning/users',
        function (req: express.Request, res: express.Response, next: express.NextFunction ): void {
            logger.log('info', 'Handling user creation request');
            if (simulatorContext.isDummyMode()) {
                next();
            } else {
                const user = req.body;
                user["status"] = 'ACTIVE';
                res.json(user);
            }
        }
    );
   
};

'use strict';

import * as wl from '@config/winston';
import * as express from 'express';

let logger = wl.init('PosConnectService');
let baseUrlLoadBalancer = '/api/v1/posconnect/rpossco'
let baseUrlPosConnect = '/rpossco'
var context;

export function initializeRoutes(app, simulatorContext) {
  context = simulatorContext
  app.post(baseUrlLoadBalancer, handler);
  app.post(baseUrlPosConnect, handler);
}

var handler = function (req: express.Request, res: express.Response, next: express.NextFunction): void {
  logger.log('info', 'Handling PosConnectMessage');
  logger.log('debug', `Request: ${JSON.stringify(req.body)}`);

  try {
    let posConnectRequest = req.body;
    let posConnectMessageType = posConnectRequest[0];
    logger.log('debug', `PosConnect request message type: ${posConnectMessageType}`);

    if (context.isDummyMode()) {
      next();
    } else {
      res.json(
        [
          posConnectMessageType + "Response",
          {
          }
        ]
      );
    }
  }
  catch (err) {
    logger.log('error', `Not a valid PosConnect message: ${err}`);
    res.status(400).send(`Not a valid PosConnect message`);
  }
}
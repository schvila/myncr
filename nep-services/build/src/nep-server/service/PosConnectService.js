'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
let logger = wl.init('PosConnectService');
let baseUrlLoadBalancer = '/api/v1/posconnect/rpossco';
let baseUrlPosConnect = '/rpossco';
var context;
function initializeRoutes(app, simulatorContext) {
    context = simulatorContext;
    app.post(baseUrlLoadBalancer, handler);
    app.post(baseUrlPosConnect, handler);
}
exports.initializeRoutes = initializeRoutes;
var handler = function (req, res, next) {
    logger.log('info', 'Handling PosConnectMessage');
    logger.log('debug', `Request: ${JSON.stringify(req.body)}`);
    try {
        let posConnectRequest = req.body;
        let posConnectMessageType = posConnectRequest[0];
        logger.log('debug', `PosConnect request message type: ${posConnectMessageType}`);
        if (context.isDummyMode()) {
            next();
        }
        else {
            res.json([
                posConnectMessageType + "Response",
                {}
            ]);
        }
    }
    catch (err) {
        logger.log('error', `Not a valid PosConnect message: ${err}`);
        res.status(400).send(`Not a valid PosConnect message`);
    }
};
//# sourceMappingURL=PosConnectService.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
let logger = wl.init('ProvisioningService');
function initializeRoutes(app, simulatorContext) {
    app.post('/provisioning/users', function (req, res, next) {
        logger.log('info', 'Handling user creation request');
        if (simulatorContext.isDummyMode()) {
            next();
        }
        else {
            const user = req.body;
            user["status"] = 'ACTIVE';
            res.json(user);
        }
    });
}
exports.initializeRoutes = initializeRoutes;
;
//# sourceMappingURL=ProvisioningService.js.map
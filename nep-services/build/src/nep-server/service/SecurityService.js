'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
let logger = wl.init('SecurityService');
const AUTH_TOKEN = "a7T1bhHJJ8dsfG1sdd2fJh9mk.nepservicessimulatortoken";
const SHARED_KEY = "515f1f1001515f1fdc0100028a808f0d";
const SECRET_KEY = "8a808f0d515f1f1001515f1fdc010002.nepservicessimulatorkey";
function initializeRoutes(app, simulatorContext) {
    app.post('/security/authentication/login', function (req, res, next) {
        logger.log('info', 'Handling authentication login');
        if (simulatorContext.isDummyMode()) {
            next();
        }
        else {
            res.json({
                "token": AUTH_TOKEN,
                "maxIdleTime": 1800,
                "maxSessionTime": 28800,
                "remainingTime": 28800
            });
        }
    });
    app.post('/security/authentication/logout', function (req, res, next) {
        logger.log('info', 'Handling authentication logout');
        if (simulatorContext.isDummyMode()) {
            next();
        }
        else {
            res.status(204).end();
        }
    });
    app.post('/security/security-access-keys', function (req, res, next) {
        logger.log('info', 'Handling request for access key generation');
        if (simulatorContext.isDummyMode()) {
            next();
        }
        else {
            const accessKey = req.body;
            const accessKeyCreation = new Date();
            accessKey["creationTimestamp"] = accessKeyCreation.toISOString();
            accessKey["sharedKey"] = SHARED_KEY;
            accessKey["secretKey"] = SECRET_KEY;
            res.json(accessKey);
        }
    });
    app.post('/security/role-grants/user-grants', function (req, res, next) {
        logger.log('info', 'Handling request for granting user roles');
        if (simulatorContext.isDummyMode()) {
            next();
        }
        else {
            res.status(204).end();
        }
    });
}
exports.initializeRoutes = initializeRoutes;
;
//# sourceMappingURL=SecurityService.js.map
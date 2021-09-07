'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
require("module-alias/register");
const minimist = require("minimist");
const wl = require("@config/winston");
const nepServer = require("./src/nep-server/nep-server");
const nepNotificationServer = require("./src/nep-server/nep-notification-server");
const Context_1 = require("./src/nep-server/simulator/Context");
let logger = wl.init('Simulator-server');
logger.log('info', `Starting Simulator manager server using arguments: ${process.argv}`);
let args = minimist(process.argv.slice(2));
if ('help' in args) {
    console.log('NEP services simulator manager');
    console.log('');
    console.log('Usage:');
    console.log('--nep-server-port {port}                NEP server port');
    console.log('--nep-notification-server-port {port}   NEP notification server port');
    console.log('--help                                  Shows help');
    console.log('');
    console.log('Examples:');
    console.log('    npm start -- --port 1245');
    console.log('    npm start -- --nep-server-port 8086');
    console.log('');
    process.exit();
}
logger.log('info', `Arguments parsed as ${JSON.stringify(args)}`);
let nepServerPort = args['nep-server-port'] || 8080;
let nepNotificationServerPort = args['nep-notification-server-port'] || 8082;
let context = new Context_1.Context();
logger.log('debug', `nepServerPort: ${nepServerPort}`);
logger.log('debug', `nepNotificationServerPort: ${nepNotificationServerPort}`);
// Initialize simulators
nepServer.initializeServer(context, nepServerPort);
nepNotificationServer.initializeServer(context, nepNotificationServerPort);
//# sourceMappingURL=index.js.map
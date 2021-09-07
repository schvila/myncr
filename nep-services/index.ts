'use strict';

import 'module-alias/register';

import * as minimist from 'minimist';
import * as wl from '@config/winston';

import * as nepServer from './src/nep-server/nep-server';
import * as nepNotificationServer from './src/nep-server/nep-notification-server';
import {Context} from './src/nep-server/simulator/Context';



let logger = wl.init('Simulator-server');
logger.log('info', `Starting Simulator manager server using arguments: ${process.argv}`)

let args: string[] = minimist(process.argv.slice(2))

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

let nepServerPort: number = args['nep-server-port'] || 8080;
let nepNotificationServerPort: number = args['nep-notification-server-port'] || 8082;
let context: Context = new Context();

logger.log('debug', `nepServerPort: ${nepServerPort}`)
logger.log('debug', `nepNotificationServerPort: ${nepNotificationServerPort}`)

// Initialize simulators
nepServer.initializeServer(context, nepServerPort);
nepNotificationServer.initializeServer(context, nepNotificationServerPort);

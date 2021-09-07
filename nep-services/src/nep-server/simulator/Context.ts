'use strict';

import * as wl from '@config/winston';
import * as waitUntil from 'async-wait-until';
import * as isSubset from 'is-subset';
import * as WebSocket from 'ws';
import * as express from 'express';
import StorageService = require('./../service/StorageService');
import * as http from 'http';

const MODE_DUMMY: string = 'Dummy';
const MODE_AUTO: string = 'Auto';
const allowedModes: string[] = [MODE_DUMMY, MODE_AUTO];

interface Request
{
    method: string,
    url: string,
    headers: http.IncomingHttpHeaders,
    body: any
}

interface IConfiguration {
    name: string;
    update: (value: string) => string;
}

export class Context {
mode: string = MODE_AUTO;
responseActions: any[] = [];
notificationClients: Map<string, WebSocket[]> = new Map<string, WebSocket[]>();

logger = wl.init('Simulator');

public requests: Request[] = [];

public getRequests(): Request[] {
    return this.requests;
};

public addRequest(req: express.Request): void {
    this.logger.log('debug', `Saving incoming request METHOD: ${req.method} URL: ${req.url}`);
    this.requests.push({ 'method': req.method, 'url': req.url, 'headers': req.headers, 'body': req.body });
};

public clearAllRequests(): void {
    this.logger.log('debug', 'Clearing request storage');
    this.requests = [];
};

public getNextRequest(timeoutMilliseconds: number): Promise<Request> {
    const _self = this;
    this.logger.log('debug', 'Dequeuing received request');

    return waitUntil(() => {
                return _self.requests.length > 0;
            }, timeoutMilliseconds)
        .then(() => {
            const request = _self.requests[0];
            _self.requests.shift();
            return request;
        });
};

public getNextRequestWithPropertiesCount(timeoutMilliseconds: number, body: express.Request, count: number): Promise<Request> {
    const _self = this;
    this.logger.log('debug', 'Get request count based on properties');

    return waitUntil(() => {
        return _self.requests
            .filter(x => isSubset(x, body))
            .length >= count;
    }, timeoutMilliseconds);
};

public addNotificationClient(topic: string, ws: WebSocket): void {
    if(!this.notificationClients.has(topic))
    {
        this.notificationClients.set(topic, []);
    }
    this.notificationClients.get(topic).push(ws);
    this.logger.log('debug', `A new notification client for ${topic} has connected`);
};

public removeNotificationClient(ws: WebSocket): void {
    var removed: boolean = false;
    this.notificationClients.forEach((value, topic) => {
        const index: number = value.indexOf(ws);

        if (index > -1) {
            value.splice(index, 1);
            removed = true;
            this.logger.log('debug', `Removed notification client for ${topic}`);
        }
    })

    if(!removed)
    {
        this.logger.log('error', 'Failed to remove notification client from list - not found');
    }
    this.logger.log('debug', 'A notification client has disconnected');
};

public sendMessageToAllNotificationClients(topic: string, payload: string): void {
    this.logger.log('debug', 'Sending a message to notification service clients');
    
    let message = {
        message: {
            topicId: {
                name: topic
            },
            payload: payload
        },
        subscription: {
            topicId: {
                name: topic
            },
        }
    };

    if(this.notificationClients.has(topic))
    {
        this.notificationClients.get(topic).forEach((ws: WebSocket) => {
            const notification = JSON.stringify(message);
            ws.send(notification);
            this.logger.log('debug', `Sent message to client ${notification}`);
        });
    }
    else
    {
        this.logger.log('debug', `No clientes registered for ${topic}`)
    }
};

public disconnectAllNotificationClients() {
    this.logger.log('debug', 'Closing connection of all notification service clients');
    let count: number = 0;
    this.notificationClients.forEach(value => {
        value.forEach(ws =>{
            ws.terminate();
            count++;
        })
    });
    return { 'DeactivatedConnectionCount': count };
};

public storeResponseAction(request: express.Request): void {
    this.logger.log('debug', 'Storing response');
    const incomingUrlRegex: string = request.body['url-regex'];
    let method: string = 'GET';
    if ('method' in request.body) {
        method = request.body['method'];
    }

    let existingAction: any = null;
    this.responseActions.forEach((action: any) => {
        const urlRegexString: string = action['url-regex'];

        if (urlRegexString === incomingUrlRegex && method === action['method']) {
            existingAction = action;
            return true;
        }
        return false;
    });

    request.body['method'] = method;

    if (existingAction === null) {
        this.responseActions.push(request.body);
    } else {
        this.logger.log('info', `Regex already exists, action will be replaced: ${incomingUrlRegex}`);
        const index: number = this.responseActions.indexOf(existingAction);
        this.responseActions[index] = request.body;
    }
};

public clearAllResponses(): void {
    this.logger.log('debug', 'Clearing response storage');
    this.responseActions = [];
};

public handleRequest(request: express.Request, response: express.Response): boolean {
    let responseFound: boolean = false;
    let actionToDelete: any = null;
    this.logger.log('debug', `Searching response action for METHOD: ${request.method} URL: ${request.url}`);
    this.responseActions.forEach((action: any) => {
        const urlRegexString: string = action['url-regex'];
        const urlRegex = new RegExp(urlRegexString);
        let method: string = 'GET';
        if ('method' in action) {
            method = action['method'];
        }

        if (request.method === method && urlRegex.test(request.url)) {
            this.logger.log('debug', `Found action with regex ${urlRegexString}`);

            const actionType: string = action['action-type'];

            if (actionType === 'SendResponse') {
                this.logger.log('debug', `Sending: ${JSON.stringify(action['response'])}`);
                response.json(action['response']);
            } else if (actionType === 'Fail') {
                response.status(action['responseCode']).json(action['response']);
            } else if (actionType === 'SendXmlResponse') {
                response.type('application/xml');
                response.send(action['response']);
            }

            if ('count' in action) {
                let useCount = parseInt(action['count']);
                useCount--;
                if (useCount < 1) {
                    actionToDelete = action;
                }
                action['count'] = useCount;
            }

            responseFound = true;
            return true;
        }
        return false;
    });

    if (!responseFound) {
        this.logger.log('debug', 'No response action has been set up for this request');
    } else if (actionToDelete !== null) {
        this.responseActions = this.responseActions.filter(function(value, index, arr){
            return value !== actionToDelete;
        });
        this.logger.log('debug', 'Action has been removed');
    }

    return responseFound;
};

updateMode(newMode: string): string {
    if (!allowedModes.includes(newMode)) {
        return `Failed to set: Unknown mode ${newMode}`;
    }

    this.logger.log('info', `Setting mode to ${newMode}`);
    this.mode = newMode;

    return 'Success';
}

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt#A_stricter_parse_function
parseIntStrict(value: string): number {
    if (/^(\-|\+)?([0-9]+|Infinity)$/.test(value)) {
        return Number(value);
    }
    return NaN;
}

updateMiniBatchThreshold(value: string): string {
    const valueNum = this.parseIntStrict(value);
    if (isNaN(valueNum)) {
        return 'Failed to parse number';
    }
    StorageService.miniBatchThreshold = valueNum;
    return 'Success';
}

updateAllowSaveFile(value: string): string {
    StorageService.allowSaveFile = (value.toLowerCase() === 'true');
    return 'Success';
}

updateUsername(value: string): string {
    StorageService.username = value;
    return 'Success';
}

updateOrganizationName(value: string): string {
    StorageService.organizationName = value;
    return 'Success';
}

allConfigs: IConfiguration[] = [
    { name: 'mode', update: this.updateMode } as IConfiguration,
    { name: 'miniBatchThreshold', update: this.updateMiniBatchThreshold } as IConfiguration,
    { name: 'allowSaveFile', update: this.updateAllowSaveFile } as IConfiguration,
    { name: 'username', update: this.updateUsername } as IConfiguration,
    { name: 'organizationName', update: this.updateOrganizationName } as IConfiguration
];

public setConfiguration(incomingAllConfiguration: any) : object{
    const result = {};
    this.allConfigs.forEach((x) => {
        const incomingValue = incomingAllConfiguration[x.name];
        if (incomingValue !== undefined) {
            result[x.name] = x.update(incomingValue);
        }
    });

    return result;
};

public isDummyMode(): boolean {
    return this.mode === MODE_DUMMY;
};
}
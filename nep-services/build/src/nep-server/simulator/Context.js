'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const waitUntil = require("async-wait-until");
const isSubset = require("is-subset");
const StorageService = require("./../service/StorageService");
const MODE_DUMMY = 'Dummy';
const MODE_AUTO = 'Auto';
const allowedModes = [MODE_DUMMY, MODE_AUTO];
class Context {
    constructor() {
        this.mode = MODE_AUTO;
        this.responseActions = [];
        this.notificationClients = new Map();
        this.logger = wl.init('Simulator');
        this.requests = [];
        this.allConfigs = [
            { name: 'mode', update: this.updateMode },
            { name: 'miniBatchThreshold', update: this.updateMiniBatchThreshold },
            { name: 'allowSaveFile', update: this.updateAllowSaveFile },
            { name: 'username', update: this.updateUsername },
            { name: 'organizationName', update: this.updateOrganizationName }
        ];
    }
    getRequests() {
        return this.requests;
    }
    ;
    addRequest(req) {
        this.logger.log('debug', `Saving incoming request METHOD: ${req.method} URL: ${req.url}`);
        this.requests.push({ 'method': req.method, 'url': req.url, 'headers': req.headers, 'body': req.body });
    }
    ;
    clearAllRequests() {
        this.logger.log('debug', 'Clearing request storage');
        this.requests = [];
    }
    ;
    getNextRequest(timeoutMilliseconds) {
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
    }
    ;
    getNextRequestWithPropertiesCount(timeoutMilliseconds, body, count) {
        const _self = this;
        this.logger.log('debug', 'Get request count based on properties');
        return waitUntil(() => {
            return _self.requests
                .filter(x => isSubset(x, body))
                .length >= count;
        }, timeoutMilliseconds);
    }
    ;
    addNotificationClient(topic, ws) {
        if (!this.notificationClients.has(topic)) {
            this.notificationClients.set(topic, []);
        }
        this.notificationClients.get(topic).push(ws);
        this.logger.log('debug', `A new notification client for ${topic} has connected`);
    }
    ;
    removeNotificationClient(ws) {
        var removed = false;
        this.notificationClients.forEach((value, topic) => {
            const index = value.indexOf(ws);
            if (index > -1) {
                value.splice(index, 1);
                removed = true;
                this.logger.log('debug', `Removed notification client for ${topic}`);
            }
        });
        if (!removed) {
            this.logger.log('error', 'Failed to remove notification client from list - not found');
        }
        this.logger.log('debug', 'A notification client has disconnected');
    }
    ;
    sendMessageToAllNotificationClients(topic, payload) {
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
        if (this.notificationClients.has(topic)) {
            this.notificationClients.get(topic).forEach((ws) => {
                const notification = JSON.stringify(message);
                ws.send(notification);
                this.logger.log('debug', `Sent message to client ${notification}`);
            });
        }
        else {
            this.logger.log('debug', `No clientes registered for ${topic}`);
        }
    }
    ;
    disconnectAllNotificationClients() {
        this.logger.log('debug', 'Closing connection of all notification service clients');
        let count = 0;
        this.notificationClients.forEach(value => {
            value.forEach(ws => {
                ws.terminate();
                count++;
            });
        });
        return { 'DeactivatedConnectionCount': count };
    }
    ;
    storeResponseAction(request) {
        this.logger.log('debug', 'Storing response');
        const incomingUrlRegex = request.body['url-regex'];
        let method = 'GET';
        if ('method' in request.body) {
            method = request.body['method'];
        }
        let existingAction = null;
        this.responseActions.forEach((action) => {
            const urlRegexString = action['url-regex'];
            if (urlRegexString === incomingUrlRegex && method === action['method']) {
                existingAction = action;
                return true;
            }
            return false;
        });
        request.body['method'] = method;
        if (existingAction === null) {
            this.responseActions.push(request.body);
        }
        else {
            this.logger.log('info', `Regex already exists, action will be replaced: ${incomingUrlRegex}`);
            const index = this.responseActions.indexOf(existingAction);
            this.responseActions[index] = request.body;
        }
    }
    ;
    clearAllResponses() {
        this.logger.log('debug', 'Clearing response storage');
        this.responseActions = [];
    }
    ;
    handleRequest(request, response) {
        let responseFound = false;
        let actionToDelete = null;
        this.logger.log('debug', `Searching response action for METHOD: ${request.method} URL: ${request.url}`);
        this.responseActions.forEach((action) => {
            const urlRegexString = action['url-regex'];
            const urlRegex = new RegExp(urlRegexString);
            let method = 'GET';
            if ('method' in action) {
                method = action['method'];
            }
            if (request.method === method && urlRegex.test(request.url)) {
                this.logger.log('debug', `Found action with regex ${urlRegexString}`);
                const actionType = action['action-type'];
                if (actionType === 'SendResponse') {
                    this.logger.log('debug', `Sending: ${JSON.stringify(action['response'])}`);
                    response.json(action['response']);
                }
                else if (actionType === 'Fail') {
                    response.status(action['responseCode']).json(action['response']);
                }
                else if (actionType === 'SendXmlResponse') {
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
        }
        else if (actionToDelete !== null) {
            this.responseActions = this.responseActions.filter(function (value, index, arr) {
                return value !== actionToDelete;
            });
            this.logger.log('debug', 'Action has been removed');
        }
        return responseFound;
    }
    ;
    updateMode(newMode) {
        if (!allowedModes.includes(newMode)) {
            return `Failed to set: Unknown mode ${newMode}`;
        }
        this.logger.log('info', `Setting mode to ${newMode}`);
        this.mode = newMode;
        return 'Success';
    }
    // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt#A_stricter_parse_function
    parseIntStrict(value) {
        if (/^(\-|\+)?([0-9]+|Infinity)$/.test(value)) {
            return Number(value);
        }
        return NaN;
    }
    updateMiniBatchThreshold(value) {
        const valueNum = this.parseIntStrict(value);
        if (isNaN(valueNum)) {
            return 'Failed to parse number';
        }
        StorageService.miniBatchThreshold = valueNum;
        return 'Success';
    }
    updateAllowSaveFile(value) {
        StorageService.allowSaveFile = (value.toLowerCase() === 'true');
        return 'Success';
    }
    updateUsername(value) {
        StorageService.username = value;
        return 'Success';
    }
    updateOrganizationName(value) {
        StorageService.organizationName = value;
        return 'Success';
    }
    setConfiguration(incomingAllConfiguration) {
        const result = {};
        this.allConfigs.forEach((x) => {
            const incomingValue = incomingAllConfiguration[x.name];
            if (incomingValue !== undefined) {
                result[x.name] = x.update(incomingValue);
            }
        });
        return result;
    }
    ;
    isDummyMode() {
        return this.mode === MODE_DUMMY;
    }
    ;
}
exports.Context = Context;
//# sourceMappingURL=Context.js.map
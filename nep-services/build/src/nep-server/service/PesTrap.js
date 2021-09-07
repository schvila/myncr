'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const logger = wl.init('PesTrap');
/**
 * Encapsulates and manages a collection of traps.
 * Traps are accessed by their ID which is provided on their creation.
 */
class TrapHive {
    constructor() {
        this.nextId = 0;
        this.traps = new Map();
    }
    createCaptureTrap(validator) {
        let trapId = this.nextId;
        this.traps.set(trapId, new CaptureTrap(trapId, validator));
        this.nextId = this.getNextId();
        return trapId;
    }
    createDelayTrap(validator, delayMs) {
        let trapId = this.nextId;
        this.traps.set(trapId, new DelayTrap(trapId, validator, delayMs));
        this.nextId = this.getNextId();
        return trapId;
    }
    getTrap(trapId) {
        return this.traps.get(trapId);
    }
    disposeTrap(id) {
        if (this.traps.has(id)) {
            this.traps.delete(id);
            this.nextId = id;
        }
    }
    clearAllTrappedMessages() {
        this.traps.forEach(trap => {
            let capture = trap;
            capture.clearMessages();
        });
    }
    async catch(type, message) {
        let promises = [];
        for (let trap of this.traps.values()) {
            promises.push(trap.catch(type, message));
        }
        await Promise.all(promises);
    }
    getNextId() {
        let id = this.nextId + 1;
        if (this.traps.keys.length < id) {
            id = 0;
        }
        while (this.traps.has(id)) {
            id++;
        }
        return id;
    }
}
exports.TrapHive = TrapHive;
/**
 * Trap base class.
 * This class provides basic validation of messages by validator method passed to constructor.
 */
class Trap {
    constructor(id, validator) {
        this.id = id;
        this.validator = (validator != null) ? validator : (callType, message) => true;
    }
    async catch(callType, message) {
        if (this.validator(callType, message)) {
            await this.process(callType, message);
        }
    }
}
/**
 * Captures and stores messages.
 * On waitForMessagesAsync returns all stored messages or blocks untils first message is captured or timeout is reached.
 */
class CaptureTrap extends Trap {
    constructor(id, validator) {
        super(id, validator);
        this.messages = [];
        this.resolver = null;
    }
    async process(callType, message) {
        if (this.resolver != null) {
            this.resolver(message);
            this.resolver = null;
            logger.log("debug", `[Trap ${this.id}] '${callType}' message resolved wait promise.`);
        }
        this.messages.push(message);
        logger.log("debug", `[Trap ${this.id}] '${callType}' message trapped.`);
    }
    async waitForMessagesAsync(ms) {
        let messages = [];
        if (this.messages.length > 0) {
            messages = this.messages;
            logger.log("debug", `[Trap ${this.id}] Returning ${this.messages.length} captured ${(this.messages.length > 1) ? "messages" : "message"}.`);
        }
        else if ((this.resolver == null) && (ms > 0)) {
            logger.log("debug", `[Trap ${this.id}] Waiting for message with timeout ${ms} ms.`);
            let promise = new Promise(resolver => {
                this.resolver = resolver;
            });
            let timeout = setTimeout(() => {
                if (this.resolver != null) {
                    this.resolver(null);
                    this.resolver = null;
                }
            }, ms);
            try {
                let message = await promise;
                if (message != null) {
                    messages.push(message);
                    logger.log("debug", `[Trap ${this.id}] Waiting for message finished successfully.`);
                }
                else {
                    logger.log("debug", `[Trap ${this.id}] Waiting for message timed out after ${ms} ms.`);
                }
            }
            finally {
                clearTimeout(timeout);
            }
        }
        return messages;
    }
    clearMessages() {
        this.messages = [];
    }
}
exports.CaptureTrap = CaptureTrap;
/**
 * Delays messages by delay passed to constructor.
 */
class DelayTrap extends Trap {
    constructor(id, validator, delayMs) {
        super(id, validator);
        this.delayMs = delayMs;
    }
    async process(callType, message) {
        await this.delay(this.delayMs);
        logger.log("debug", `[Trap ${this.id}] '${callType}' message delayed by ${this.delayMs} ms.`);
    }
    delay(delayTimeout) {
        return new Promise(resolve => setTimeout(resolve, delayTimeout));
    }
}
//# sourceMappingURL=PesTrap.js.map
'use strict';

import * as wl from '@config/winston';
const logger = wl.init('PesTrap');

/**
 * Encapsulates and manages a collection of traps.
 * Traps are accessed by their ID which is provided on their creation.
 */
export class TrapHive<T> {
    private nextId: number;
    private traps: Map<number, Trap<T>>;

    constructor() {
        this.nextId = 0;
        this.traps = new Map<number, Trap<T>>();
    }

    createCaptureTrap(validator: (callType: string, instance: T) => boolean): number {
        let trapId : number = this.nextId;
        this.traps.set(trapId, new CaptureTrap<T>(trapId, validator));
        this.nextId = this.getNextId();
        return trapId;
    }

    createDelayTrap(validator: (callType: string, instance: T) => boolean, delayMs: number): number {
        let trapId : number = this.nextId;
        this.traps.set(trapId, new DelayTrap<T>(trapId, validator, delayMs));
        this.nextId = this.getNextId();
        return trapId;
    }

    getTrap<TrapSpecialization extends Trap<T>>(trapId: number): TrapSpecialization {
        return this.traps.get(trapId) as TrapSpecialization;
    }

    disposeTrap(id: number): void {
        if (this.traps.has(id)) {
            this.traps.delete(id);
            this.nextId = id;
        }
    }

    async catch(type: string, message: T): Promise<void> {
        let promises: Promise<void>[] = [];
        for (let trap of this.traps.values()) {
            promises.push(trap.catch(type, message));
        }
        await Promise.all(promises);
    }

    private getNextId(): number {
        let id: number = this.nextId + 1;
        if (this.traps.keys.length < id) {
            id = 0;
        }
        while (this.traps.has(id)) {
            id++;
        }
        return id;
    }
}

/**
 * Trap base class.
 * This class provides basic validation of messages by validator method passed to constructor.
 */
abstract class Trap<T> {
    protected readonly id: number;
    protected readonly validator: (callType: string, message: T) => boolean;

    constructor(id: number, validator: (callType: string, message: T) => boolean) {
        this.id = id;
        this.validator = (validator != null) ? validator : (callType: string, message: T) => true;
    }

    async catch(callType: string, message: T): Promise<void> {
        if (this.validator(callType, message)) {
            await this.process(callType, message);
        }
    }

    protected abstract async process(callType: string, message: T): Promise<void>;
}

/**
 * Captures and stores messages.
 * On waitForMessagesAsync returns all stored messages or blocks untils first message is captured or timeout is reached.
 */
export class CaptureTrap<T> extends Trap<T> {
    private messages: T[];
    private resolver: ((message: T) => void);

    constructor(id: number, validator: (callType: string, message: T) => boolean) {
        super(id, validator);
        this.messages = [];
        this.resolver = null;
    }

    protected async process(callType: string, message: T): Promise<void> {
        if (this.resolver != null)
        {
            this.resolver(message);
            this.resolver = null;
            logger.log("debug", `[Trap ${this.id}] '${callType}' message resolved wait promise.`);
        }

        this.messages.push(message);
        logger.log("debug", `[Trap ${this.id}] '${callType}' message trapped.`);
    }

    async waitForMessagesAsync(ms: number): Promise<T[]> {
        let messages: T[] = [];

        if (this.messages.length > 0)
        {
            messages = this.messages;
            logger.log("debug", `[Trap ${this.id}] Returning ${this.messages.length} captured ${(this.messages.length > 1) ? "messages" : "message"}.`);
        }
        else if ((this.resolver == null) && (ms > 0))
        {
            logger.log("debug", `[Trap ${this.id}] Waiting for message with timeout ${ms} ms.`);

            let promise: Promise<T> = new Promise<T>(resolver => { 
                this.resolver = resolver;
            });

            let timeout = setTimeout(() => {
                if (this.resolver != null) {
                    this.resolver(null);
                    this.resolver = null;
                }
            }, ms);
            
            try
            {
                let message: T = await promise;
                if (message != null) {
                    messages.push(message);
                    logger.log("debug", `[Trap ${this.id}] Waiting for message finished successfully.`);
                } else {
                    logger.log("debug", `[Trap ${this.id}] Waiting for message timed out after ${ms} ms.`);
                }
            }
            finally
            {
                clearTimeout(timeout);
            }
        }

        return messages;
    }

    clearMessages(): void {
        this.messages = []
    }
}

/**
 * Delays messages by delay passed to constructor.
 */
class DelayTrap<T> extends Trap<T> {
    private delayMs: number;

    constructor(id: number, validator: (callType: string, message: T) => boolean, delayMs: number) {
        super(id, validator);
        this.delayMs = delayMs;
    }

    protected async process(callType: string, message: T): Promise<void> {
        await this.delay(this.delayMs);
        logger.log("debug", `[Trap ${this.id}] '${callType}' message delayed by ${this.delayMs} ms.`);
    }

    private delay(delayTimeout: number): Promise<void> {
        return new Promise(resolve => setTimeout(resolve, delayTimeout));
    }
}
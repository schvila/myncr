'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const Promotions_1 = require("./Promotions");
const PesTrap_1 = require("./PesTrap");
class CommonPromotion {
    constructor(moduleName, simulatorContext) {
        this.logger = wl.init(moduleName);
        this.consumers = new Map();
        this.promotions = [];
        this.trapHive = new PesTrap_1.TrapHive();
        this.receiptMessages = [];
        this.customStatusCode = null;
        this.supportedCards = [];
        this.messages = this.getArrayWithLimitedLength();
        this.pinAuthPromptId = "PIN_AUTH";
        this.simulatorContext = simulatorContext;
    }
    initializeConsumers(body) {
        let consumers = new Map();
        if ("consumers" in body) {
            const data = body.consumers;
            const propertyNames = ["identifierStatus", "consumerStatus", "firstName", "lastName", "internalId"];
            data.forEach((consumer) => {
                let consumerData = {};
                for (const propertyName of propertyNames) {
                    if (propertyName in consumer) {
                        consumerData[propertyName] = consumer[propertyName];
                    }
                    ;
                }
                ;
                consumers.set(JSON.stringify([consumer.identifier, consumer.type]), consumerData);
            });
        }
        ;
        return consumers;
    }
    initializePromotions(body) {
        let promotions = [];
        if ("promotions" in body) {
            const data = body.promotions;
            data.forEach((promotion) => {
                switch (promotion.type) {
                    case Promotions_1.PromotionType.BasicItem:
                        promotions.push(new Promotions_1.BasicItemPromotion(promotion));
                        break;
                    case Promotions_1.PromotionType.BasicOrder:
                        promotions.push(new Promotions_1.BasicOrderPromotion(promotion));
                        break;
                    case Promotions_1.PromotionType.TransactionOverLimit:
                        promotions.push(new Promotions_1.TransactionOverLimitPromotion(promotion));
                        break;
                }
            });
        }
        ;
        return promotions;
    }
    initializeReceiptMessages(body) {
        let messages = [];
        if ("receiptMessages" in body) {
            messages = body.receiptMessages;
        }
        ;
        return messages;
    }
    initializeSupportedCards(body) {
        let supportedCards = [];
        if ("supportedCards" in body) {
            supportedCards = body.supportedCards;
        }
        ;
        return supportedCards;
    }
    initializeReferencedPromotions(body) {
        let referencedPromotions = [];
        if ("referencedPromotions" in body) {
            referencedPromotions = body.referencedPromotions;
        }
        ;
        return referencedPromotions;
    }
    generateConsumerData(body) {
        let consumerData = {};
        if (this.consumers !== undefined && ("consumerIds" in body) && (body.consumerIds.length > 0) && ("identifier" in body.consumerIds[0]) && ("type" in body.consumerIds[0])) {
            let key = JSON.stringify([body.consumerIds[0].identifier, body.consumerIds[0].type]);
            if (this.consumers.has(key)) {
                consumerData = this.consumers.get(key);
            }
        }
        ;
        return consumerData;
    }
    generateRewardPrompts(body, approvals) {
        let rewardPrompts = [];
        if ("items" in body) {
            const items = body.items;
            this.promotions.forEach((promotion) => {
                if (promotion.requiresRewardApproval() && !promotion.isApproved(approvals) && !promotion.isRejected(approvals) && promotion.isApplicable(items)) {
                    const rewardPrompt = {
                        "promotionId": promotion.data.rewardApproval.promotionId,
                        "description": promotion.data.rewardApproval.description,
                        "notificationFor": promotion.data.rewardApproval.notificationFor,
                        "promotionName": promotion.data.rewardApproval.promotionName,
                        "promotionDescription": promotion.data.rewardApproval.promotionDescription
                    };
                    rewardPrompts.push(rewardPrompt);
                }
            });
        }
        return rewardPrompts;
    }
    generateLocalPrompts(body, approvals) {
        let localPrompts = [];
        if ("items" in body) {
            const items = body.items;
            this.promotions.forEach((promotion) => {
                if (promotion.requiresPrompt() && !promotion.isApproved(approvals) && !promotion.isRejected(approvals) && promotion.isApplicable(items)) {
                    const localPrompt = {
                        "promptId": promotion.data.prompts.promptId,
                        "notificationFor": promotion.data.prompts.notificationFor,
                        "message": promotion.data.prompts.message,
                        "timeoutData": promotion.data.prompts.timeoutData
                    };
                    localPrompts.push(localPrompt);
                }
            });
        }
        return localPrompts;
    }
    generateFreePrompts(body) {
        let prompts = [];
        let checkResponsePrompt = (prompt) => {
            let possibleResponses = ["booleanResponse", "selectedOptions", "freeTextResponse", "numericResponse"];
            return prompt.promptId == this.pinAuthPromptId || possibleResponses.some((response, index, array) => response in prompt);
        };
        if ("prompts" in body) {
            if (body.prompts.find(checkResponsePrompt)) {
                return [];
            }
        }
        if ("totals" in body && body.totals === true && "consumerIds" in body) {
            body.consumerIds.forEach((consumerId) => {
                let idx = this.supportedCards.findIndex((card) => {
                    return card.cardNumber == consumerId.identifier;
                });
                if (idx !== -1) {
                    let card = this.supportedCards[idx];
                    const freePrompt = {
                        "promptId": idx.toString(),
                        "notificationFor": card.notificationFor,
                        "message": card.promptMessage,
                        "promptType": card.promptType,
                        "timeoutData": card.timeoutData
                    };
                    prompts.push(freePrompt);
                }
            });
        }
        return prompts;
    }
    generateNumericPrompts(body) {
        let numericPrompts = [];
        if ("prompts" in body) {
            const prompts = body.prompts;
            if (prompts.find((prompt) => "numericResponse" in prompt)) {
                return [];
            }
            prompts.forEach((prompt) => {
                if ("booleanResponse" in prompt && prompt.booleanResponse) {
                    let card = this.supportedCards[Number(prompt.promptId)];
                    const numericPrompt = {
                        "promptId": this.pinAuthPromptId,
                        "promptType": "NUMERIC",
                        "message": "Enter Code",
                        "notificationFor": card.notificationFor,
                        "maskInput": card.maskInput,
                        "minLength": card.minPinLength,
                        "maxLength": card.maxPinLength,
                        "timeoutData": card.timeoutData,
                        "injectedPromptId": "PIN"
                    };
                    numericPrompts.push(numericPrompt);
                }
            });
        }
        return numericPrompts;
    }
    generateItemLevelAppliedRewards(body, approvals) {
        let itemPromotions = [];
        if ("items" in body) {
            const items = body.items;
            items.forEach((item) => {
                let itemPromotion = {
                    "sequenceId": item.sequenceId,
                    "itemName": item.itemName,
                    "discountRewards": []
                };
                if ((item.itemCode != undefined) &&
                    (item.itemCode != "") &&
                    (item.itemCode != "0")) {
                    itemPromotion["itemCode"] = item.itemCode;
                }
                if ((item.categoryCode != undefined) &&
                    (item.categoryCode != "") &&
                    (item.categoryCode != "0")) {
                    itemPromotion["categoryCode"] = item.categoryCode;
                }
                this.promotions.forEach((iPromotion) => {
                    if (iPromotion instanceof Promotions_1.ItemPromotion) {
                        let promotion = iPromotion;
                        if (promotion.isApplicable(items) && promotion.isApplicableToTransactionItem(item) && !promotion.isRejected(approvals)) {
                            // Limit the quantity of the discount based on the reward limit
                            let itemQuantity = item.quantity.units;
                            if (this.referencedPromotions != undefined) {
                                this.referencedPromotions.forEach((referencedPromotion) => {
                                    if (referencedPromotion.promotionId === promotion.data.promotionId) {
                                        if ((referencedPromotion.rewardLimit != undefined) &&
                                            (referencedPromotion.rewardLimit < itemQuantity)) {
                                            itemQuantity = referencedPromotion.rewardLimit;
                                        }
                                    }
                                });
                            }
                            itemPromotion.discountRewards.push(promotion.getItemLevelDiscountReward(itemQuantity));
                        }
                        ;
                    }
                });
                if (itemPromotion.discountRewards.length > 0) {
                    itemPromotions.push(itemPromotion);
                }
                ;
            });
        }
        ;
        return itemPromotions;
    }
    generateOrderLevelAppliedRewards(body, approvals) {
        let orderPromotion = null;
        if ("items" in body) {
            const items = body.items;
            this.promotions.forEach((promotion) => {
                if (promotion instanceof Promotions_1.OrderPromotion && promotion.isApplicable(items) && !promotion.isRejected(approvals)) {
                    if (orderPromotion === null) {
                        orderPromotion = {
                            "discountRewards": []
                        };
                    }
                    orderPromotion.discountRewards.push(promotion.getOrderLevelDiscountReward());
                }
                ;
            });
        }
        return orderPromotion;
    }
    generateSellingEngineNotifications(request_type = 'get') {
        let sellingEngineNotifications = [{
                "receiptMessages": this.receiptMessages[request_type],
                "referencedPromotions": this.referencedPromotions
            }];
        return sellingEngineNotifications;
    }
    generateNotifications(rewardApprovals, prompts) {
        let notification = [{
                "maxRewardApprovals": 1,
                "rewardApprovals": rewardApprovals,
                "prompts": prompts
            }
        ];
        return notification;
    }
    generateHeaders() {
        let headers = [
            ["nep-correlation-id", "340abfe3-1707-439a-bc79-97ced0dbaa3c"]
        ];
        return headers;
    }
    readRewardApprovals(body) {
        let rewardApprovals = new Map();
        if ("rewardApprovals" in body) {
            const approvals = body.rewardApprovals;
            approvals.forEach((approval) => {
                rewardApprovals.set(approval.promotionId, approval.approvalFlag);
            });
        }
        ;
        return rewardApprovals;
    }
    readLocalPrompts(body) {
        let localPrompts = new Map();
        if ("prompts" in body) {
            const prompts = body.prompts;
            prompts.forEach((prompt) => {
                localPrompts.set(prompt.promptId, prompt.approvalFlag);
            });
        }
        return localPrompts;
    }
    getTrapValidator(body) {
        if ("callType" in body) {
            return (callType, message) => callType == body.callType;
        }
        return (callType, message) => true;
    }
    getArrayWithLimitedLength() {
        var array = new Array();
        array.push = function () {
            if (this.length >= 100) {
                this.shift();
            }
            return Array.prototype.push.apply(this, arguments);
        };
        return array;
    }
    getCustomStatusCode() {
        const useCode = this.customStatusCode != null;
        return { use: useCode, value: this.customStatusCode };
    }
    checkHeaders(headers) {
        const requiredHeaders = ["content-type", "nep-enterprise-unit", "nep-organization", "nep-device-id"];
        const actualHeaders = Object.keys(headers);
        return requiredHeaders.every(header => actualHeaders.includes(header));
    }
    async getPromotions(req, res, next) {
        this.logger.log('info', 'Handling get promotions request');
        this.logger.log('debug', JSON.stringify(req.body));
        await this.trapHive.catch("Get", req.body);
        if (this.simulatorContext.isDummyMode()) {
            next();
        }
        else {
            const statusCode = this.getCustomStatusCode();
            if (statusCode.use) {
                res.status(statusCode.value).end();
            }
            else {
                const approvals = this.readRewardApprovals(req.body);
                const prompts = this.readLocalPrompts(req.body);
                const consumer = this.generateConsumerData(req.body);
                const rewardPrompts = this.generateRewardPrompts(req.body, approvals);
                const localPrompts = this.generateLocalPrompts(req.body, prompts);
                const freePrompts = this.generateFreePrompts(req.body);
                const numericPrompts = this.generateNumericPrompts(req.body);
                let resBody = {
                    "orderBeginDateTime": req.body["orderBeginDateTime"],
                    "consumer": consumer,
                };
                let now = new Date();
                resBody.providerResponseTime = now;
                if (rewardPrompts.length > 0) {
                    resBody.notifications = this.generateNotifications(rewardPrompts, {});
                }
                else if (freePrompts.length > 0) {
                    resBody.notifications = this.generateNotifications({}, freePrompts);
                }
                else if (numericPrompts.length > 0) {
                    resBody.notifications = this.generateNotifications({}, numericPrompts);
                }
                else {
                    resBody.itemLevelAppliedRewards = this.generateItemLevelAppliedRewards(req.body, approvals);
                    resBody.orderLevelAppliedRewards = this.generateOrderLevelAppliedRewards(req.body, approvals);
                    resBody.sellingEngineNotifications = this.generateSellingEngineNotifications('get');
                    resBody.notifications = this.generateNotifications({}, localPrompts);
                }
                ;
                if (this.checkHeaders(req.headers)) {
                    const headers = this.generateHeaders();
                    for (const header of headers) {
                        res.set(header[0], header[1]);
                    }
                    console.log(JSON.stringify(resBody));
                    res.json(resBody);
                }
                else {
                    this.logger.log('error', "HTTP request has missing required header.");
                    res.status(400).end();
                }
            }
        }
        ;
        this.messages.push(req.body);
    }
    async finalize(req, res) {
        this.logger.log('info', 'Handling sync-finalize promotions request');
        this.logger.log('debug', JSON.stringify(req.body));
        await this.trapHive.catch("SyncFinalize", req.body);
        await this.trapHive.catch("Finalize", req.body);
        if (this.checkHeaders(req.headers)) {
            const headers = this.generateHeaders();
            for (const header of headers) {
                res.set(header[0], header[1]);
            }
            const statusCode = this.getCustomStatusCode();
            if (statusCode.use) {
                res.status(statusCode.value).end();
            }
            else {
                const consumer = this.generateConsumerData(req.body);
                let resBody = {
                    "orderBeginDateTime": req.body["orderBeginDateTime"],
                    "consumer": consumer,
                };
                resBody.sellingEngineNotifications = this.generateSellingEngineNotifications('sync-finalize');
                res.json(resBody);
                res.status(200).end();
            }
        }
        else {
            this.logger.log('error', "HTTP request has missing required header.");
            res.status(400).end();
        }
        this.messages.push(req.body);
    }
    async voidPromotion(req, res) {
        this.logger.log('info', 'Handling void promotions request');
        this.logger.log('debug', JSON.stringify(req.body));
        await this.trapHive.catch("Void", req.body);
        if (this.checkHeaders(req.headers)) {
            const headers = this.generateHeaders();
            for (const header of headers) {
                res.set(header[0], header[1]);
            }
            const statusCode = this.getCustomStatusCode();
            if (statusCode.use) {
                res.status(statusCode.value).end();
            }
            else {
                res.status(204).end();
            }
        }
        else {
            this.logger.log('error', "HTTP request has missing required header.");
            res.status(400).end();
        }
        this.messages.push(req.body);
    }
    configure(req, res) {
        this.consumers = this.initializeConsumers(req.body);
        this.promotions = this.initializePromotions(req.body);
        this.receiptMessages = this.initializeReceiptMessages(req.body);
        this.supportedCards = this.initializeSupportedCards(req.body);
        this.referencedPromotions = this.initializeReferencedPromotions(req.body);
        res.json({
            "configured": true
        });
    }
    getMessages(req, res) {
        res.json(this.messages);
    }
    deleteMessages(req, res) {
        const resBody = {
            "deletedMessages": this.messages.length
        };
        this.messages.length = 0;
        res.json(resBody);
    }
    captureTrap(req, res) {
        const trapId = this.trapHive.createCaptureTrap(this.getTrapValidator(req.body));
        res.json({ "trapId": trapId });
    }
    delayTrap(req, res) {
        const reqBody = req.body;
        if ("trapDelay" in reqBody) {
            const delay = reqBody.trapDelay;
            const trapId = this.trapHive.createDelayTrap(this.getTrapValidator(req.body), delay);
            res.json({ "trapId": trapId });
        }
        else {
            res.status(400).send("Missing 'trapDelay' element in request.");
        }
    }
    deleteTrap(req, res) {
        const reqBody = req.body;
        if ("trapId" in reqBody) {
            const trapId = reqBody.trapId;
            this.trapHive.disposeTrap(trapId);
            res.json({ "result": "success" });
        }
        else {
            res.status(400).send("Missing 'trapId' element in request.");
        }
    }
    async waitForMessages(req, res) {
        const reqBody = req.body;
        if (("trapId" in reqBody) && ("timeout" in reqBody)) {
            const trapId = reqBody.trapId;
            const timeout = reqBody.timeout;
            try {
                const trap = this.trapHive.getTrap(trapId);
                if (trap != null) {
                    let messages = await trap.waitForMessagesAsync(timeout);
                    res.json(messages);
                }
                else {
                    res.status(400).send(`Invalid trap ID ${trapId}.`);
                }
            }
            catch (exception) {
                res.status(500).send(exception);
            }
        }
        else {
            res.status(400).send("Missing 'trapId' or 'timeout' element in request.");
        }
    }
    deleteTrappedMessages(req, res) {
        const reqBody = req.body;
        if ("trapId" in reqBody) {
            const trapId = reqBody.trapId;
            const trap = this.trapHive.getTrap(trapId);
            if (trap != null) {
                trap.clearMessages();
                res.json({ "result": "success" });
            }
            else {
                res.status(400).send(`Invalid trap ID ${trapId}.`);
            }
        }
        else {
            res.status(400).send("Missing 'trapId' element in request.");
        }
    }
    addCustomStatusCode(req, res) {
        const reqBody = req.body;
        if ("statusCode" in reqBody) {
            const statusCode = reqBody.statusCode;
            this.customStatusCode = statusCode;
            res.json({ "result": "success" });
        }
        else {
            res.status(400).send("Missing 'statusCode' element in request.");
        }
    }
    deleteCustomStatusCode(req, res) {
        const clear_trapped = req.query.clear;
        if (clear_trapped == 'true') {
            this.logger.log('info', 'Clearing all trapped messages.');
            this.trapHive.clearAllTrappedMessages();
        }
        this.customStatusCode = null;
        res.json({ "result": "success" });
    }
}
exports.CommonPromotion = CommonPromotion;
//# sourceMappingURL=CommonPromotion.js.map
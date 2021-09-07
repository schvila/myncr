'use strict';

import * as wl from '@config/winston';
import * as express from 'express';
import { skipIfDummyMode } from './ServiceCommon';
import { PromotionType, BasicItemPromotion, BasicOrderPromotion, ItemPromotion, OrderPromotion, IPromotion, TransactionOverLimitPromotion } from './Promotions';
import { TrapHive, CaptureTrap } from './PesTrap';

const logger = wl.init('PromotionExecutionService');
let consumers : Map<string, object>
let promotions: Array<IPromotion> = [];
let trapHive: TrapHive<any> = new TrapHive<any>();
let receiptMessages: Array<any> = [];
let customStatusCode: number = null;
const messages = getArrayWithLimitedLength();

function initializeConsumers(body: any) {
    let consumers = new Map<string, object>();
    if ("consumers" in body) {
        const data = body.consumers;
        const propertyNames = ["identifierStatus", "consumerStatus", "firstName", "lastName", "internalId"];
        data.forEach((consumer: any) => {
            let consumerData:any = {};
            for(const propertyName of propertyNames) {
                if (propertyName in consumer) {
                    consumerData[propertyName] = consumer[propertyName];
                };
            };

            consumers.set(JSON.stringify([consumer.identifier, consumer.type]), consumerData);
        });
    };

    return consumers;
}

function initializePromotions(body: any) {
    let promotions: Array<IPromotion> = [];
    if ("promotions" in body) {
        const data = body.promotions;
        data.forEach((promotion: any) => {
            switch(promotion.type) {
                case PromotionType.BasicItem:
                    promotions.push(new BasicItemPromotion(promotion));
                    break;
                case PromotionType.BasicOrder:
                    promotions.push(new BasicOrderPromotion(promotion));
                    break;
                case PromotionType.TransactionOverLimit:
                    promotions.push(new TransactionOverLimitPromotion(promotion));
                    break;
            }
        });
    };

    return promotions;
}

function initializeReceiptMessages(body: any) {
    let messages: Array<any> = [];

    if ("receiptMessages" in body) {
        messages = body.receiptMessages;
    };

    return messages;
}

function generateConsumerData(body: any) {
    let consumerData = {};
    if (consumers !== undefined && ("consumerIds" in body) && (body.consumerIds.length > 0) && ("identifier" in body.consumerIds[0]) && ("type" in body.consumerIds[0])) {
        let key = JSON.stringify([body.consumerIds[0].identifier, body.consumerIds[0].type]);
        if (consumers.has(key))
        {          
            consumerData = consumers.get(key);
        }
    };

    return consumerData;
}

function generateRewardPrompts(body: any, approvals:Map<string, string>) {
    let rewardPrompts = [];
    if ("items" in body) {
        const items:any = body.items;
        promotions.forEach((promotion: IPromotion) => {
            if (promotion.requiresRewardApproval() && !promotion.isApproved(approvals) && !promotion.isRejected(approvals) && promotion.isApplicable(items)) {
                const rewardPrompt:any = {
                    "promotionId": promotion.data.promotionId,
                    "description" : promotion.data.rewardApproval.description,
                    "notificationFor" : promotion.data.rewardApproval.notificationFor,
					"promotionName" : promotion.data.rewardApproval.promotionName,
					"promotionDescription" : promotion.data.rewardApproval.promotionDescription
                }

                rewardPrompts.push(rewardPrompt);
            }
        });

    }

    return rewardPrompts;
}

function generateItemLevelAppliedRewards(body: any, approvals:Map<string, string>) {
    let itemPromotions = [];
    if ("items" in body) {
        const items:any = body.items;

        items.forEach((item: any) => {
            let itemPromotion = {
                "sequenceId" : item.sequenceId,
                "categoryCode" : item.categoryCode,
                "itemName" : item.itemName,
                "discountRewards" : []
            };

            promotions.forEach((iPromotion: IPromotion) => {
                if (iPromotion instanceof ItemPromotion) {
                    let promotion: ItemPromotion = <ItemPromotion> iPromotion;
                    if (promotion.isApplicableToTransactionItem(item) && promotion.isApplicable(items) && !promotion.isRejected(approvals)) {
                        itemPromotion.discountRewards.push(promotion.getItemLevelDiscountReward(item.quantity.units));
                    };
                }
            });

            if (itemPromotion.discountRewards.length > 0) {
                itemPromotions.push(itemPromotion);
            };
        });
    };

    return itemPromotions;
}

function generateOrderLevelAppliedRewards(body: any, approvals:Map<string, string>) {
    let orderPromotion = null;
    if ("items" in body) {
        const items:any = body.items;

        promotions.forEach((promotion: IPromotion) => {
            if (promotion instanceof OrderPromotion && promotion.isApplicable(items) && !promotion.isRejected(approvals)) {
                if (orderPromotion === null) {
                    orderPromotion = {
                        "discountRewards" : []
                    }
                }
                orderPromotion.discountRewards.push(promotion.getOrderLevelDiscountReward());
            };
        });
    }

    return orderPromotion;
}

function generateSellingEngineNotifications(request_type = 'get') {
    let sellingEngineNotifications = [{
        "receiptMessages": receiptMessages[request_type]
    }];
    
    return sellingEngineNotifications;
}

function generateNotifications(prompts: any) {
    let notification = [ {
            "maxRewardApprovals": 1,
            "rewardApprovals": prompts
        }
    ];

    return notification;
}

function readRewardApprovals(body: any) {
    let rewardApprovals = new Map<string, string>();
    if ("rewardApprovals" in body) {
        const approvals = body.rewardApprovals;
        approvals.forEach((approval: any) => {
            rewardApprovals.set(approval.promotionId, approval.approvalFlag);
        });
    };

    return rewardApprovals;
}

function getTrapValidator(body: any): (callType: string, message: any) => boolean {
    if ("callType" in body) {
        return (callType: string, message: any) => callType == body.callType;
    }

    return (callType: string, message: any) => true;
}

function getArrayWithLimitedLength() {
    var array = new Array();

    array.push = function () {
        if (this.length >= 100) {
            this.shift();
        }
        return Array.prototype.push.apply(this,arguments);
    }

    return array;

}

function getCustomStatusCode() {
    const useCode: boolean = customStatusCode != null;
    return { use: useCode, value: customStatusCode }
}

function checkHeaders(headers : any) {
    const requiredHeaders = ["content-type", "nep-enterprise-unit", "nep-application-key", "nep-organization", "nep-device-id"]
    const actualHeaders = Object.keys(headers)
    return requiredHeaders.every(header => actualHeaders.includes(header))
}

export function initializeRoutes(app, simulatorContext) {
   /**
     * @swagger
     * /promotion-execution/promotions/get:
     *  post:
     *      summary: This rest endpoint will be called when an inquiry is being made as to if there are any applicable rewards to be given to the consumer.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: https://developer.ncr.com/portals/dev-portal/api-explorer/details/10/documentation?version=1.9.0-20190807121816-707cce4&path=post_promotions_get
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: string
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.post('/promotion-execution/promotions/get',
        async (req: express.Request, res: express.Response, next: express.NextFunction ): Promise<void> => {
            logger.log('info', 'Handling get promotions request');
            
            await trapHive.catch("Get", req.body);

            if (simulatorContext.isDummyMode()) {
                next();
            } else {
                const statusCode = getCustomStatusCode();
                if (statusCode.use) {
                    res.status(statusCode.value).end();
                } else {
                    const approvals:Map<string, string> = readRewardApprovals(req.body);
                    const consumer = generateConsumerData(req.body);
                    const prompts = generateRewardPrompts(req.body, approvals);

                    let resBody:any = {
                        "orderBeginDateTime" : req.body["orderBeginDateTime"],
                        "consumer" : consumer,
                    };

                    if (prompts.length > 0) {
                        resBody.notifications = generateNotifications(prompts);
                    } else {
                        resBody.itemLevelAppliedRewards = generateItemLevelAppliedRewards(req.body, approvals);
                        resBody.orderLevelAppliedRewards = generateOrderLevelAppliedRewards(req.body, approvals);
                        resBody.sellingEngineNotifications = generateSellingEngineNotifications('get');
                    };

                    if(checkHeaders(req.headers)) {
                        res.json(resBody);
                    } else {
                        logger.log('error', "HTTP request has missing required header.");
                        res.status(400).end();
                    }
                }
            };

            messages.push(req.body);
        });

   /**
     * @swagger
     * /promotion-execution/promotions/finalize:
     *  post:
     *      summary: This rest endpoint is used to finalize the consumer's orders, and hence awarded rewards
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: https://developer.ncr.com/portals/dev-portal/api-explorer/details/10/documentation?version=1.9.0-20190807121816-707cce4&path=post_promotions_finalize
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: string
     *      responses:
     *          204:
     *              description: Success.
     */
    app.post('/promotion-execution/promotions/finalize', skipIfDummyMode(simulatorContext), async (req: express.Request, res: express.Response): Promise<void> => {
        logger.log('info', 'Handling finalize promotions request');

        await trapHive.catch("Finalize", req.body);

        if(checkHeaders(req.headers)) {
            const statusCode = getCustomStatusCode()
            if (statusCode.use) {
                res.status(statusCode.value).end();
            } else {
                const consumer = generateConsumerData(req.body);
                let resBody:any = {
                    "orderBeginDateTime" : req.body["orderBeginDateTime"],
                    "consumer" : consumer,
                };

                resBody.sellingEngineNotifications = generateSellingEngineNotifications('finalize');
                res.json(resBody);
                res.status(200).end();
            }
        } else {
            logger.log('error', "HTTP request has missing required header.");
            res.status(400).end();
        }

        messages.push(req.body);
    });

   /**
     * @swagger
     * /promotion-execution/promotions/sync-finalize:
     *  post:
     *      summary: This rest endpoint is used to finalize the consumer's order and allows the partner to return a limited subset of data that does not modify the check
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: https://developer.ncr.com/portals/dev-portal/api-explorer/details/10/documentation?version=1.20.0&path=post_promotions_sync-finalize
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: string
     *      responses:
     *          204:
     *              description: Success.
     */
    app.post('/promotion-execution/promotions/sync-finalize', skipIfDummyMode(simulatorContext), async (req: express.Request, res: express.Response): Promise<void> => {
        logger.log('info', 'Handling sync-finalize promotions request');

        await trapHive.catch("SyncFinalize", req.body);

        if(checkHeaders(req.headers)) {
            const statusCode = getCustomStatusCode()
            if (statusCode.use) {
                res.status(statusCode.value).end();
            } else {
                const consumer = generateConsumerData(req.body);
                let resBody:any = {
                    "orderBeginDateTime" : req.body["orderBeginDateTime"],
                    "consumer" : consumer,
                };

                resBody.sellingEngineNotifications = generateSellingEngineNotifications('sync-finalize');
                res.json(resBody);
                res.status(200).end();
            }
        } else {
            logger.log('error', "HTTP request has missing required header.");
            res.status(400).end();
        }

        messages.push(req.body);
    });

    /**
     * @swagger
     * /promotion-execution/promotions/void:
     *  post:
     *      summary: This rest endpoint is used to void orders
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: https://developer.ncr.com/portals/dev-portal/api-explorer/details/10/documentation?version=1.9.0-20190807121816-707cce4&path=post_promotions_void
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: string
     *      responses:
     *          204:
     *              description: Success.
     */
    app.post('/promotion-execution/promotions/void', skipIfDummyMode(simulatorContext), async (req: express.Request, res: express.Response): Promise<void> => {
        logger.log('info', 'Handling void promotions request');

        await trapHive.catch("Void", req.body);

        if(checkHeaders(req.headers)) {
            const statusCode = getCustomStatusCode()
            if (statusCode.use) {
                res.status(statusCode.value).end();
            } else {
                res.status(204).end();
            }
        } else {
            logger.log('error', "HTTP request has missing required header.");
            res.status(400).end();
        }

        messages.push(req.body);
    });

    // ---------------------------------------------------
    // PRIVATE SIMULATOR METHODS
    //----------------------------------------------------
    /**
     * @swagger
     * /promotion-execution/simulator/configuration:
     *  post:
     *      summary: configures promotions and consumers in PES simulator
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: json with consumers and promotions
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          consumers:
     *                              type: array
     *                              items:
     *                                  type: object
     *                                  properties:
     *                                      identifier:
     *                                          type: string
     *                                      type:
     *                                          type: string
     *                                      identifierStatus:
     *                                          type: string
     *                                      consumerStatus:
     *                                          type: string
     *                                      firstName:
     *                                          type: string
     *                                      lastName:
     *                                          type: string
     *                                      internalId:
     *                                          type: string
     *                          promotions:
     *                              type: array
     *                              items:
     *                                  type: object
     *                                  properties:
     *                                      promotionId:
     *                                          type: string
     *                                      type:
     *                                          type: string
     *                                      trigger:
     *                                          type: array
     *                                          items:
     *                                              type: object
     *                                              properties:
     *                                                  matchingItems:
     *                                                      type: array 
     *                                                      items:
     *                                                          type: object
     *                                                          properties:
     *                                                              categoryCode:
     *                                                                  type: string
     *                                                              quantity:
     *                                                                  type: integer
     *                                                  matchingCards:
     *                                                      type: array
     *                                                      items:
     *                                                          type: string
     *                                                  limit:
     *                                                      type: string
     *                                      rewardApproval:
     *                                          type: object
     *                                          properties:
     *                                              description:
     *                                                  type: array
     *                                                  items:
     *                                                      type: object
     *                                                      properties:
     *                                                          key:
     *                                                              type: string
     *                                                          value:
     *                                                              type: string
     *                                              notificationFor:
     *                                                  type: string
     *                                      discounts:
     *                                          type: array
     *                                          items:
     *                                              type: object
     *                                              properties:
     *                                                  amount:
     *                                                      type: string
     *                                                  quantity:
     *                                                      type: object
     *                                                      properties:
     *                                                          units:
     *                                                              type: integer
     *                                                          unitType:
     *                                                              type: string
     *                                                  matchNetUnitPrice:
     *                                                      type: integer
     *                                                  flexNegative:
     *                                                      type: string
     *                                                  unitCalculateAmount:
     *                                                      type: integer
     *                                                  returnsAmount:
     *                                                      type: integer
     *                                                  fundingDepts:
     *                                                      type: array
     *                                                      items:
     *                                                          type: string
     *                                                  isApplyMarkup:
     *                                                      type: boolean
     *                                                  isReturnsProration:
     *                                                      type: boolean
     *                                                  subSequenceIds:
     *                                                      type: array
     *                                                      items:
     *                                                          type: string
     *                                                  triggeredItems:
     *                                                      type: array
     *                                                      items:
     *                                                          type: string
     *                                                  isApplyAsTender:
     *                                                      type: boolean
     *                          receiptMessages:
     *                              type: array
     *                              items:
     *                                  type: object
     *                                  properties:
     *                                      lines:
     *                                          type: array
     *                                          required: true
     *                                          items:
     *                                              type: object
     *                                              properties:
     *                                                  attributes:
     *                                                      type: object
     *                                                      required: true
     *                                                      properties:
     *                                                          location:
     *                                                              type: string
     *                                                              required: true
     *                                                              enum: [
     *                                                                  DEFAULT,
     *                                                                  FRONT,
     *                                                                  BACK
     *                                                              ]
     *                                                          type:
     *                                                              type: string
     *                                                              required: true
     *                                                              enum: [
     *                                                                  TEXT,
     *                                                                  LOGO,
     *                                                                  BIG_LOGO,
     *                                                                  UPCA,
     *                                                                  UPCE,
     *                                                                  EAN8,
     *                                                                  JAN8,
     *                                                                  EAN13,
     *                                                                  JAN13,
     *                                                                  CODABAR,
     *                                                                  CODE39,
     *                                                                  CODE93,
     *                                                                  CODE128,
     *                                                                  OPOS
     *                                                              ]
     *                                                          sortId:
     *                                                              type: integer
     *                                                              required: true
     *                                                          contentType:
     *                                                              type: string
     *                                                              required: true
     *                                                              enum: [
     *                                                                  GENERAL_RECEIPT_MESSAGE,
     *                                                                  REWARD_SUMMARY_MESSAGE,
     *                                                                  RECEIPT_TRAILER_MESSAGE
     *                                                              ]
     *                                                          alignment:
     *                                                              type: string
     *                                                              required: true
     *                                                              enum: [
     *                                                                  LEFT,
     *                                                                  CENTER,
     *                                                                  RIGHT
     *                                                              ]
     *                                                          formats:
     *                                                              type: array
     *                                                              required: true
     *                                                              items:
     *                                                                  type: string
     *                                                                  enum: [
     *                                                                      NO_FORMATTING,
     *                                                                      DOUBLE_WIDE,
     *                                                                      DOUBLE_HIGH,
     *                                                                      BOLD,
     *                                                                      ITALICS,
     *                                                                      UNDERLINE,
     *                                                                      INVERT,
     *                                                                      ALTERNATE_COLOR,
     *                                                                      RESERVED
     *                                                                  ]
     *                                                          lineBreak:
     *                                                              type: string
     *                                                              required: true
     *                                                              enum: [
     *                                                                  NO_LINE_BREAK,
     *                                                                  LINE_BREAK_BEFORE_PRINTLINE,
     *                                                                  LINE_BREAK_AFTER_PRINTLINE,
     *                                                                  LINE_BREAK_BEFORE_AFTER_PRINTLINE,
     *                                                                  PRINTER_CUT_AFTER_PRINTLINE,
     *                                                                  LINE_BREAK_BEFORE_PRINTER_CUT_AFTER_PRINTLINE
     *                                                              ]
     *                                              content:
     *                                                  type: string
     *                                                  required: true
     *                                      locale:
     *                                          type: string
     *                  example:
     *                      {
     *                          "consumers":[
     *                              {
     *                                  "identifier":"1234444321",
     *                                  "type":"PHONE",
     *                                  "identifierStatus":"ACTIVE",
     *                                  "consumerStatus":"ACTIVE",
     *                                  "firstName":"John",
     *                                  "lastName":"Doe",
     *                                  "internalId":"string"
     *                              }
     *                          ],
     *                          "promotions":[
     *                              {
     *                                  "promotionId":"dollarofffries",
     *                                  "type": "basicItem",
     *                                  "trigger":{
     *                                      "matchingItems":[
     *                                          {
     *                                              "categoryCode":"87",
     *                                              "quantity":1
     *                                         },
     *                                         {
     *                                             "categoryCode":"95",
     *                                             "quantity":1
     *                                         }
     *                                     ],
     *                                     "matchingCards":[
     *                                         "1234444321"
     *                                     ]
     *                                 },
     *                                 "rewardApproval":{
     *                                     "description":[
     *                                         {
     *                                             "key":"fullDescription",
     *                                             "value":"Take $1 off any size fries!"
     *                                         }
     *                                     ],
     *                                     "notificationFor":"CASHIER_AND_CONSUMER"
     *                                 },
     *                                 "discounts":[
     *                                     {
     *                                         "amount":1,
     *                                         "quantity":{
     *                                             "units":1,
     *                                             "unitType":"SIMPLE_QUANTITY"
     *                                          },
     *                                          "matchNetUnitPrice":0,
     *                                          "flexNegative":"NOT_FLEXED",
     *                                          "unitCalculateAmount":0,
     *                                          "returnsAmount":0,
     *                                          "fundingDepts":[
     *
     *                                          ],
     *                                          "isApplyMarkup":false,
     *                                          "isReturnsProration":false,
     *                                          "subSequenceIds":[
     *
     *                                          ],
     *                                          "triggeredItems":[
     *
     *                                          ],
     *                                          "isApplyAsTender":false
     *                                      }
     *                                  ]
     *                              },
     *                              {
     *                                  "promotionId":"dollarofffries-orderlevel",
     *                                  "type": "basicOrder",
     *                                  "trigger":{
     *                                      "matchingItems":[
     *                                          {
     *                                              "categoryCode":"87",
     *                                              "quantity":1
     *                                          }
     *                                      ],
     *                                      "matchingCards":[
     *                                          "1234444321"
     *                                      ]
     *                                  },
     *                                  "rewardApproval":{
     *                                      "description":[
     *                                          {
     *                                              "key":"dollarofffries-orderlevel",
     *                                              "value":"Take $1 off of your order when you buy any size fries!!"
     *                                          }
     *                                      ],
     *                                      "notificationFor":"CASHIER_AND_CONSUMER"
     *                                  },
     *                                  "discounts":[
     *                                      {
     *                                          "amount":1,
     *                                          "quantity":{
     *                                              "units":1,
     *                                              "unitType":"SIMPLE_QUANTITY"
     *                                          },
     *                                          "matchNetUnitPrice":0,
     *                                          "flexNegative":"NOT_FLEXED",
     *                                          "unitCalculateAmount":0,
     *                                          "returnsAmount":0,
     *                                          "fundingDepts":[
     *
     *                                          ],
     *                                          "isApplyMarkup":false,
     *                                          "isReturnsProration":false,
     *                                          "subSequenceIds":[
     *
     *                                          ],
     *                                          "triggeredItems":[
     *
     *                                          ],
     *                                          "isApplyAsTender":false
     *                                      }
     *                                  ]
     *                              },
     *                              {
     *                                  "promotionId":"transactionoverlimit-orderlevel",
     *                                  "type":"transactionOverLimit",
     *                                  "trigger":{
     *                                      "limit":2,
     *                                      "matchingCards":[
     *                                          "1234444321"
     *                                      ]
     *                                  },
     *                                  "discounts":[
     *                                      {
     *                                          "amount":1,
     *                                          "quantity":{
     *                                              "units":1,
     *                                              "unitType":"SIMPLE_QUANTITY"
     *                                          },
     *                                          "matchNetUnitPrice":0,
     *                                          "flexNegative":"NOT_FLEXED",
     *                                          "unitCalculateAmount":0,
     *                                          "returnsAmount":0,
     *                                          "fundingDepts":[
     *
     *                                          ],
     *                                          "isApplyMarkup":false,
     *                                          "isReturnsProration":false,
     *                                          "subSequenceIds":[
     *
     *                                          ],
     *                                          "triggeredItems":[
     *
     *                                          ],
     *                                          "isApplyAsTender":false
     *                                      }
     *                                  ]
     *                              },
     *                          ],
     *                          "receiptMessages": [
     *                              {
     *                                  "lines": [
     *                                      {
     *                                          "attributes": {
     *                                              "location": "BACK",
     *                                              "type": "TEXT",
     *                                              "sortId": 0,
     *                                              "contentType": "RECEIPT_TRAILER_MESSAGE",
     *                                              "alignment": "CENTER",
     *                                              "formats": [
     *                                                  "BOLD"
     *                                              ],
     *                                              "lineBreak": "LINE_BREAK_BEFORE_AFTER_PRINTLINE"
     *                                          },
     *                                          "content": "Thank you for using our loyalty"
     *                                      }
     *                                  ],
     *                                  "locale": "en-GB"
     *                              }
     *                          ]
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.post('/promotion-execution/simulator/configuration', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        consumers = initializeConsumers(req.body);
        promotions = initializePromotions(req.body);
        receiptMessages = initializeReceiptMessages(req.body);
        res.json({
            "configured" : true
        });
    });

    /**
     * @swagger
     * /promotion-execution/simulator/messages:
     *  get:
     *      summary: Returns the message queue in the PES simulator
     *      tags:
     *          - PES interface
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.get('/promotion-execution/simulator/messages', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        res.json(messages);
    });

    /**
     * @swagger
     * /promotion-execution/simulator/messages:
     *  delete:
     *      summary: Clears message queue in the PES simulator
     *      tags:
     *          - PES interface
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.delete('/promotion-execution/simulator/messages', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const resBody:any = {
            "deletedMessages" : messages.length
        };

        messages.length = 0;
        res.json(resBody);
    });

    /**
     * @swagger
     * /promotion-execution/simulator/capture-trap:
     *  get:
     *      summary: Creates capture message trap with validator specified in requestBody and returns trap ID.
     *               Capture message trap captures requests incoming to PES simulator which fulfill provided validator condition and provides them on waitForMessage call.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: JSON with trap validator method definition
     *          required: false
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          callType:
     *                              type: string
     *                              enum: ["Get", "Finalize", "SyncFinalize", "Void"]
     *                  example:
     *                      {
     *                          "callType": "Get"
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.get('/promotion-execution/simulator/capture-trap', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const trapId: number = trapHive.createCaptureTrap(getTrapValidator(req.body));
        res.json({ "trapId": trapId });
    });

    /**
     * @swagger
     * /promotion-execution/simulator/delay-trap:
     *  get:
     *      summary: Creates delay message trap with delay and validator specified in requestBody and returns trap ID.
     *               Delay message trap delays execution of requests incoming to PES simulator which fulfill provided validator condition by specified delay time.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: JSON with trap validator method definition
     *          required: false
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          callType:
     *                              type: string
     *                              enum: ["Get", "Finalize", "SyncFinalize", "Void"]
     *                          trapDelay:
     *                              type: number
     *                  example:
     *                      {
     *                          "callType": "Get"
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     *          400:
     *              description: Missing "trapDelay" element.
     */
    app.get('/promotion-execution/simulator/delay-trap', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const reqBody: any = req.body;
        if ("trapDelay" in reqBody) {
            const delay: number = reqBody.trapDelay;
            const trapId: number = trapHive.createDelayTrap(getTrapValidator(req.body), delay);
            res.json({ "trapId": trapId });
        } else {
            res.status(400).send("Missing 'trapDelay' element in request.");
        }
    });

    /**
     * @swagger
     * /promotion-execution/simulator/trap:
     *  delete:
     *      summary: Disposes trap specified by ID in requestBody.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: json with trap ID
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          trapId:
     *                              type: integer
     *                  example:
     *                      {
     *                          "trapId":0
     *                      }
     *      responses:
     *          204:
     *              description: Success.
     *          400:
     *              description: Missing "trapId" element.
     */
    app.delete('/promotion-execution/simulator/trap', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const reqBody: any = req.body;
        if ("trapId" in reqBody) {
            const trapId: number = reqBody.trapId;
            trapHive.disposeTrap(trapId);
            res.json({ "result": "success" });
        } else {
            res.status(400).send("Missing 'trapId' element in request.");
        }
    });

    /**
     * @swagger
     * /promotion-execution/simulator/waitForMessages:
     *  get:
     *      summary: Waits for until a message is trapped by a trap specified by ID or until timeout is reached.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: json with trap ID and timeout in milliseconds
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          trapId:
     *                              type: integer
     *                          timeout:
     *                              type: integer
     *                  example:
     *                      {
     *                          "trapId":0,
     *                          "timeout":1000
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     *          500:
     *              description: Waiting for message failed.
     *          400:
     *              description: Missing "trapId" or "timeout" element.
     */
    app.get('/promotion-execution/simulator/waitForMessages', skipIfDummyMode(simulatorContext), async (req: express.Request, res: express.Response): Promise<void> => {
        const reqBody: any = req.body;
        if (("trapId" in reqBody) && ("timeout" in reqBody))
        {
            const trapId: number = reqBody.trapId;
            const timeout: number = reqBody.timeout;

            try {
                const trap: CaptureTrap<any> = trapHive.getTrap<CaptureTrap<any>>(trapId);
                if (trap != null) {
                    let messages: any[] = await trap.waitForMessagesAsync(timeout);
                    res.json(messages);
                } else {
                    res.status(400).send(`Invalid trap ID ${trapId}.`);
                }
            } catch (exception) {
                res.status(500).send(exception);
            }
        } else {
            res.status(400).send("Missing 'trapId' or 'timeout' element in request.");
        }
    });

    /**
     * @swagger
     * /promotion-execution/simulator/trappedMessages:
     *  delete:
     *      summary: Clears messages captured by a trap specified by ID.
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: json with trap ID
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          trapId:
     *                              type: integer
     *                  example:
     *                      {
     *                          "trapId":0
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     *          400:
     *              description: Missing "trapId" element.
     */
    app.delete('/promotion-execution/simulator/trappedMessages', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const reqBody: any = req.body;
        if ("trapId" in reqBody) {
            const trapId: number = reqBody.trapId;
            const trap: CaptureTrap<any> = trapHive.getTrap<CaptureTrap<any>>(trapId);
            if (trap != null) {
                trap.clearMessages();
                res.json({ "result": "success" });
            } else {
                res.status(400).send(`Invalid trap ID ${trapId}.`);
            }
        } else {
            res.status(400).send("Missing 'trapId' element in request.");
        }
    });

    /**
     * @swagger
     * /promotion-execution/simulator/customStatusCode:
     *  post:
     *      summary: Sets a custom http status code which will be returned instead of response for get/finalize/sync-finalize/void promotions response
     *      tags:
     *          - PES interface
     *      requestBody:
     *          description: json with status code
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      type: object
     *                      properties:
     *                          statusCode:
     *                              type: integer
     *                  example:
     *                      {
     *                          "statusCode":404
     *                      }
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     *          400:
     *              description: Missing "statusCode" element.
     */
    app.post('/promotion-execution/simulator/customStatusCode', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        const reqBody: any = req.body;
        if ("statusCode" in reqBody) {
            const statusCode: number = reqBody.statusCode;
            customStatusCode = statusCode;
            res.json({ "result": "success" });
        } else {
            res.status(400).send("Missing 'statusCode' element in request.");
        }
    });

    /**
     * @swagger
     * /promotion-execution/simulator/customStatusCode:
     *  delete:
     *      summary: Clears configured custom status code or do nothing if the status code is not configured.
     *      tags:
     *          - PES interface
     *      responses:
     *          200:
     *              description: Success.
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: string
     */
    app.delete('/promotion-execution/simulator/customStatusCode', skipIfDummyMode(simulatorContext), (req: express.Request, res: express.Response): void => {
        customStatusCode = null;
        res.json({ "result": "success" });
    });
}

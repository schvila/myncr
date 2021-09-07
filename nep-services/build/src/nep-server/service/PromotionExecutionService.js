'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const CommonPromotion_1 = require("./CommonPromotion");
const ServiceCommon_1 = require("./ServiceCommon");
function initializeRoutes(app, simulatorContext) {
    let commonPromotion = new CommonPromotion_1.CommonPromotion('PromotionExecutionService', simulatorContext);
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
    app.post('/promotion-execution/promotions/get', (req, res, next) => commonPromotion.getPromotions(req, res, next));
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
    app.post('/promotion-execution/promotions/sync-finalize', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.finalize(req, res));
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
    app.post('/promotion-execution/promotions/void', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.voidPromotion(req, res));
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
     *                          supportedCards:
     *                               type: array
     *                               items:
     *                                   type: object
     *                                   properties:
     *                                       cardNumber:
     *                                           type: string
     *                                           required: true
     *                                       promptType:
     *                                           type: string
     *                                           required: true
     *                                           enum: [
     *                                               BOOLEAN,
     *                                               NUMERIC,
     *                                               FREE_TEXT,
     *                                               MULTI_SELECT
     *                                           ]
     *                                       promptMessage:
     *                                           type: string
     *                                           required: false
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
     *                          ],
     *                          "supportedCards": [
     *                              {
     *                                  "cardNumber": "1234444321",
     *                                  "promptType": "BOOLEAN",
     *                                  "promptMessage": "Apply this fantastic discount?"
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
    app.post('/promotion-execution/simulator/configuration', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.configure(req, res));
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
    app.get('/promotion-execution/simulator/messages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.getMessages(req, res));
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
    app.delete('/promotion-execution/simulator/messages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.deleteMessages(req, res));
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
    app.get('/promotion-execution/simulator/capture-trap', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.captureTrap(req, res));
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
    app.get('/promotion-execution/simulator/delay-trap', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.delayTrap(req, res));
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
    app.delete('/promotion-execution/simulator/trap', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.deleteTrap(req, res));
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
    app.get('/promotion-execution/simulator/waitForMessages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.waitForMessages(req, res));
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
    app.delete('/promotion-execution/simulator/trappedMessages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.deleteTrap(req, res));
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
    app.post('/promotion-execution/simulator/customStatusCode', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.addCustomStatusCode(req, res));
    /**
     * @swagger
     * /promotion-execution/simulator/customStatusCode:
     *  delete:
     *      summary: Clears configured custom status code or do nothing if the status code is not configured.
     *      parameters:
     *          - in: query
     *            name: clear
     *            schema:
     *                type: string
     *            description: Value 'true' means all trapped messages should be deleted. Default is 'false'.
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
    app.delete('/promotion-execution/simulator/customStatusCode', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => commonPromotion.deleteCustomStatusCode(req, res));
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=PromotionExecutionService.js.map
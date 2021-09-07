# Describe what kind of json you expect.
definitions = {
    "quantity": {
        "type": "object",
        "properties": {
            "units": {
                "type": "number"
            },
            "unitType": {
                "enum": ["GRAMS", "GRAINS", "OUNCES", "POUNDS", "STONES", "KILOGRAMS", "TONS_LONG", "TONS_METRIC", "CENTILITER", "CUBIC_CENTIMETER", "CUBIC_DECIMETER", "CUBIC_DECAMETER", "CUBIC_FOOT", "CUBIC_INCH", "CUBIC_METER", "CUBIC_MILLIMETER", "CUBIC_YARD", "DECILITER", "DRAM", "GALLON_UK", "GALLON_US_DRY", "GALLON_US_LIQUID", "GILL_UK", "GILL_US", "IMPERIAL_GALLON", "JIGGER", "KILOLITER", "LITER", "MILLILITER", "OUNCE_UK_LIQUID", "OUNCE_US_LIQUID", "PINT_UK", "PINT_US_DRY", "PINT_US_LIQUID", "QUART_UK", "QUART_US_DRY", "QUART_US_LIQUID", "SHOT", "YARDS", "METERS", "SQUARE_YARDS", "SQUARE_METERS", "SIMPLE_QUANTITY", "GENERIC_UNIT_SALES"]
            }
        },
        "required": ["units", "unitType"]
    },
    "description": {
        "type": "object",
        "properties": {
            "key": {
                "type": "string"
            },
            "value": {
                "type": "string"
            },
            "localizedValue": {
                "type": "object",
                "properties": {
                    "values": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "locale": {
                                    "type": "string"
                                },
                                "value": {
                                    "type": "string"
                                }
                            },
                            "required": ["locale", "value"]
                        }
                    }
                }
            }
        },
        "required": ["key"]
    },
    "programType": {
        "enum": ["POINTS", "STORED_VALUE", "VISITS"]
    },
    "calculationType": {
        "enum": ["CENTS_OFF", "PERCENT_OFF", "PRICE_POINT", "PERCENT_OFF_PER_ITEM"]
    },
    "rewardCalculationType": {
        "enum": ["DEFAULT", "REWARDS_ON_NET", "REWARD_ON_GROSS"]
    },        
    "type": {
        "enum": ["PROMOTIONAL_DISCOUNT", "PRICE_OVERRIDE", "PRICE_OVERRIDE_WITH_MARKUP"]
    }
}

schema:dict = {}
schema['get'] = {
    "type": "object",
    "definitions": definitions,
    "properties": {
        "orderId": {
            "type": "string"
        },
        "orderBeginDateTime": {
            "type": "string"
        },
        "loyaltyBarcode": {
            "type": "string"
        },
        "checkDetails": {
            "type": "object",
            "properties": {
                "checkId": {
                    "type": "string"
                },
                "siteId": {
                    "type": "string"
                },
                "dateOfBusiness": {
                    "type": "string"
                },
                "trainingMode": {
                    "type": "boolean"
                },
                "cashierID": {
                    "type": "string"
                },
                "deviceGroup": {
                    "type": "string"
                },
                "posId": {
                    "type": "string"
                },
                "pumpId": {
                    "type": "string"
                },
                "tillId": {
                    "type": "string"
                }
            }
        },
        "appliedRewards": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "promotionId": {
                        "type": "string"
                    },
                    "alternatePromotionId": {
                        "type": "string"
                    },
                    "amount": {
                        "type": "number"
                    },
                    "redemptionCount": {
                        "type": "integer"
                    }
                },
                "required": ["promotionId", "amount"]
            }
        },
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "sequenceId": {
                        "type": "integer"
                    },
                    "itemCode": {
                        "type": "string"
                    },
                    "itemName": {
                        "type": "string"
                    },
                    "parentSequenceId": {
                        "type": "integer"
                    },
                    "quantity": {
                        "$ref": "#/definitions/quantity"
                    },
                    "unitPrice": {
                        "type": "number"
                    },
                    "alternatePrice": {
                        "type": "number"
                    },
                    "discountable": {
                        "type": "boolean"
                    },
                    "considerForOrderLevelRewards": {
                        "type": "boolean"
                    },
                    "clearanceLevel": {
                        "enum": ["NOT_ON_CLEARANCE", "LEVEL_1", "LEVEL_2", "LEVEL_3", "LEVEL_4", "LEVEL_5", "LEVEL_6", "LEVEL_7", "LEVEL_8", "LEVEL_9", "LEVEL_10"]
                    },
                    "departmentId": {
                        "type": "string"
                    },
                    "familyCode": {
                        "type": "integer"
                    },
                    "companyPrefix": {
                        "type": "string"
                    },
                    "shippingPrice": {
                        "type": "number"
                    },
                    "adjustments": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "getReturnsProrations": {
                                    "type": "boolean"
                                },
                                "calculationType": {
                                    "$ref": "#/definitions/calculationType"
                                },
                                "adjustmentValue": {
                                    "type": "number"
                                },
                                "appliesToNonDiscountableItems": {
                                    "type": "boolean"
                                },
                                "rewardCalculationType": {
                                    "$ref": "#/definitions/rewardCalculationType"
                                },
                                "fundingDepartmentId": {
                                    "type": "string"
                                },
                                "priority": {
                                    "type": "integer"
                                },
                                "type": {
                                    "$ref": "#/definitions/type"
                                },
                                "sequenceId": {
                                    "type": "integer"
                                },
                                "quantity": {
                                    "$ref": "#/definitions/quantity"
                                },
                                "itemPriceToMatch": {
                                    "type": "number"
                                },
                                "promotionId": {
                                    "type": "string"
                                },
                                "alternatePromotionId": {
                                    "type": "string"
                                }
                            },
                            "required": ["calculationType", "adjustmentValue", "appliesToNonDiscountableItems", "fundingDepartmentId", "priority", "type", "sequenceId", "quantity"]
                        }
                    },
                    "categoryCode": {
                        "type": "string"
                    },
                    "serviceMode": {
                        "enum": ["SELF_SERVICE", "FULL_SERVICE"]
                    },
                    "tenderType": {
                        "enum": ["CASH", "CREDIT"]
                    }
                },
                "required": ["sequenceId", "itemCode", "quantity", "unitPrice", "discountable", "considerForOrderLevelRewards"]
            }
        },
        "returnItems": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "sequenceId": {
                        "type": "integer"
                    },
                    "itemCode": {
                        "type": "string"
                    },
                    "itemName": {
                        "type": "string"
                    },
                    "quantity": {
                        "$ref": "#/definitions/quantity"
                    },
                    "unitPrice": {
                        "type": "number"
                    },
                    "discountable": {
                        "type": "boolean"
                    },
                    "considerForOrderLevelRewards": {
                        "type": "boolean"
                    },
                    "returnedLoyalties": {
                        "type": "object",
                        "properties": {
                            "promotionId": {
                                "type": "string"
                            },
                            "alternatePromotionId": {
                                "type": "string"
                            },
                            "description": {
                                "$ref": "#/definitions/description"
                            },
                            "programId": {
                                "type": "integer"
                            },
                            "programType": {
                                "$ref": "#/definitions/programType"
                            },
                            "itemQuantity": {
                                "type": "integer"
                            },
                            "units": {
                                "type": "integer"
                            },
                            "expiration": {
                                "type": "string"
                            },
                            "matchNetUnitPrice": {
                                "type": "number"
                            },
                            "subSequenceIds": {
                                "type": "array"
                            },
                            "amount": {
                                "type": "number"
                            }
                        },
                        "required": ["promotionId", "description", "programId", "programType", "itemQuantity", "units", "matchNetUnitPrice", "subSequenceIds"]
                    },
                    "adjustments": {
                        "type": "object",
                        "properties": {
                            "getReturnsProrations": {
                                "type": "boolean"
                            },
                            "calculationType": {
                                "$ref": "#/definitions/calculationType"
                            },
                            "adjustmentValue": {
                                "type": "number"
                            },
                            "appliesToNonDiscountableItems": {
                                "type": "boolean"
                            },
                            "rewardCalculationType": {
                                "$ref": "#/definitions/rewardCalculationType"
                            },
                            "fundingDepartmentId": {
                                "type": "string"
                            },
                            "priority": {
                                "type": "integer"
                            },
                            "type": {
                                "$ref": "#/definitions/type"
                            },
                            "sequenceId": {
                                "type": "integer"
                            },
                            "quantity": {
                                "$ref": "#/definitions/quantity"
                            },
                            "itemPriceToMatch": {
                                "type": "number"
                            },
                            "promotionId": {
                                "type": "string"
                            },
                            "alternatePromotionId": {
                                "type": "string"
                            }
                        },
                        "required": ["calculationType", "adjustmentValue", "appliesToNonDiscountableItems", "fundingDepartmentId", "priority", "type", "sequenceId", "quantity"]
                    }
                },
                "required": ["sequenceId", "itemCode", "quantity", "unitPrice", "discountable", "considerForOrderLevelRewards"]
            }
        },
        "coupons": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "sequenceId": {
                        "type": "integer"
                    },
                    "couponCode": {
                        "type": "string"
                    },
                    "couponType": {
                        "enum": ["TRIGGER_CODE", "TRACKABLE_COUPON", "MANUAL_COUPON", "STORE_COUPON", "MANUFACTURER_COUPON", "GS1COUPON", "DIGITAL_COUPON", "UPC5"]
                    },
                    "numberOfUses": {
                        "type": "integer"
                    },
                    "rewardMultiplier": {
                        "type": "integer"
                    },
                    "couponAdjustment": {
                        "type": "object",
                        "properties": {
                            "getReturnsProrations": {
                                "type": "boolean"
                            },
                            "calculationType": {
                                "$ref": "#/definitions/calculationType"
                            },
                            "adjustmentValue": {
                                "type": "number"
                            },
                            "appliesToNonDiscountableItems": {
                                "type": "boolean"
                            },
                            "rewardCalculationType": {
                                "$ref": "#/definitions/rewardCalculationType"
                            },
                            "fundingDepartmentId": {
                                "type": "string"
                            },
                            "priority": {
                                "type": "integer"
                            },
                            "itemSequenceId": {
                                "type": "integer"
                            },
                            "adjustmentLevel": {
                                "enum": ["ITEM_LEVEL", "ORDER_LEVEL"]
                            },
                            "itemPriceToMatch": {
                                "type": "number"
                            },
                            "quantityLimit": {
                                "$ref": "#/definitions/quantity"
                            },
                            "returned": {
                                "type": "boolean"
                            },
                        },
                        "required": ["calculationType", "adjustmentValue", "appliesToNonDiscountableItems", "fundingDepartmentId", "priority", "adjustmentLevel"]
                    },
                    "skipValidation": {
                        "type": "boolean"
                    }
                },
                "required": ["sequenceId"]
            }
        },
        "consumerIds": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "identifierStatus": {
                        "enum": ["ACTIVE", "INACTIVE"]
                    },
                    "consumerStatus": {
                        "enum": ["ACTIVE", "INACTIVE"]
                    },
                    "firstName": {
                        "type": "string"
                    },
                    "lastName": {
                        "type": "string"
                    },
                    "internalId": {
                        "type": "string"
                    },
                    "programBalances": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "programId": {
                                    "type": "number"
                                },
                                "programType": {
                                    "$ref": "#/definitions/programType"
                                },
                                "programName": {
                                    "type": "string"
                                },
                                "openingBalance": {
                                    "type": "number"
                                },
                                "closingBalance": {
                                    "type": "number"
                                },
                                "earnedPoints": {
                                    "type": "number"
                                },
                                "burnedPoints": {
                                    "type": "number"
                                }
                            }
                        }
                    },
                    "identifier": {
                        "type": "string"
                    },
                    "type": {
                        "enum": ["LOYALTY_ID", "EMAIL", "PHONE", "OTHERS"]
                    },
                    "otherType": {
                        "type": "string"
                    },
                    "entryMethod": {
                        "enum": ["SWIPE", "MANUAL", "SCAN", "RFID"]
                    }
                },
                "required": ["identifier"]
            }
        },
        "shipping": {
            "type": "object",
            "properties": {
                "sequenceId": {
                    "type": "integer"
                },
                "type": {
                    "enum": ["FLAT_RATE", "TABLE_RATE", "FREE", "PICKUP", "CARRIERS"]
                },
                "price": {
                    "type": "number"
                }
            },
            "required": ["sequenceId", "type", "price"]
        },
        "redeemLoyalty": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "promotionId": {
                        "type": "string"
                    },
                    "alternatePromotionId": {
                        "type": "string"
                    },
                    "description": {
                        "$ref": "#/definitions/description"
                    },
                    "programId": {
                        "type": "integer"
                    },
                    "programType": {
                        "$ref": "#/definitions/programType"
                    },
                    "amount": {
                        "type": "number"
                    },
                    "sequenceId": {
                        "type": "integer"
                    }
                },
                "required": ["promotionId", "description", "programId", "programType", "sequenceId"]
            }
        },
        "tenders": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "sequenceId": {
                        "type": "integer"
                    },
                    "tenderType": {
                        "enum": ["CASH", "CREDIT_DEBIT", "CHECK", "HOUSE_ACCOUNT", "PURCHASE_ORDER", "FOOD_STAMPS", "VOUCHER", "MANUFACTURE_COUPON", "COPAY", "LOYALTY", "TRAVELERS_CHECK", "CHECK_CARD", "GIFT_CERTIFICATE", "STORED_VALUE", "WIC_CHECK", "CUSTOMER_ACCOUNT", "COUPON", "UK_MAESTRO", "CAPITALBOND", "STAFF_DRESS_ALLOWANCE", "AIR_MILES_CONVERSION", "INTERNATIONAL_MAESTRO", "ELECTRONIC_TOLL_COLLECTION", "ACCOUNTS_RECEIVABLE", "OTHER"]
                    },
                    "tenderSubType": {
                        "enum": ["VISA", "MASTERCARD", "DINERCLUB", "DISCOVERCARD", "FLEET", "OTHER"]
                    },
                    "otherTenderType": {
                        "type": "string"
                    },
                    "otherSubTenderType": {
                        "type": "string"
                    },
                    "amount": {
                        "type": "number"
                    }
                },
                "required": ["sequenceId", "tenderType", "amount"]
            }
        },
        "orderLevelAdjustments": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "getReturnsProrations": {
                        "type": "boolean"
                    },
                    "calculationType": {
                        "$ref": "#/definitions/calculationType"
                    },
                    "adjustmentValue": {
                        "type": "number"
                    },
                    "appliesToNonDiscountableItems": {
                        "type": "boolean"
                    },
                    "rewardCalculationType": {
                        "$ref": "#/definitions/rewardCalculationType"
                    },
                    "fundingDepartmentId": {
                        "type": "string"
                    },
                    "priority": {
                        "type": "integer"
                    },
                    "returned": {
                        "type": "boolean"
                    },
                    "type": {
                        "$ref": "#/definitions/type"
                    },
                    "sequenceId": {
                        "type": "integer"
                    },
                    "promotionId": {
                        "type": "string"
                    },
                    "alternatePromotionId": {
                        "type": "string"
                    }
                },
                "required": ["calculationType", "adjustmentValue", "appliesToNonDiscountableItems", "fundingDepartmentId", "priority", "type", "sequenceId"]
            }
        },
        "orderTotals": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "value": {
                        "type": "number"
                    },
                    "type": {
                        "enum": ["TAX_INCLUDED", "TAX_EXCLUDED", "ITEM_TOTAL"]
                    }
                },
                "required": ["value", "type"]
            }
        },
        "rewardApprovals": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "promotionId": {
                        "type": "string"
                    },
                    "alternatePromotionId": {
                        "type": "string"
                    },
                    "sequenceId": {
                        "type": "integer"
                    },
                    "approvalFlag": {
                        "enum": ["APPROVE", "REJECT"]
                    }
                },
                "required": ["promotionId", "sequenceId", "approvalFlag"]
            }
        },
        "prompts": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "promptId": {
                        "type": "string"
                    },
                    "sequenceId": {
                        "type": "integer"
                    },
                    "approvalFlag": {
                        "enum": ["APPROVE", "REJECT"]
                    }
                },
                "required": ["promotionId", "sequenceId", "approvalFlag"]
            }
        },
        "totals": {
            "type": "boolean"
        },
        "channelType": {
            "enum": ["POS", "MOBILE", "ONLINE"]
        },
        "payment": {
            "enum": ["COLLECTED", "NOT_COLLECTED"]
        },
        "dynamicAttributes": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "type": {
                        "type": "string"
                    },
                    "attributes": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "key": {
                                    "type": "string"
                                },
                                "value": {
                                    "type": "string"
                                }
                            },
                            "required": ["key"]
                        }
                    }
                },
                "required": ["type", "attributes"]
            }
        },
        "transactionOrigin": {
            "enum": ["POS", "TERMINAL", "KIOSK"]
        },
        "transactionType": {
            "enum": ["PREPAY", "POSTPAY", "PAY_AT_PUMP"]
        }
    },
    "additionalProperties": False,
    "required": ["orderId", "orderBeginDateTime"]
}

schema['finalize'] = schema['get']

schema['sync-finalize'] = schema['finalize']

schema['void'] = {
    "type": "object",
    "properties": {
        "orderId": {
            "type": "string"
        }
    },
    "additionalProperties": False,
    "required": ["orderId"]
}
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const _ = require("lodash");
var PromotionType;
(function (PromotionType) {
    PromotionType["BasicItem"] = "basicItem";
    PromotionType["BasicOrder"] = "basicOrder";
    PromotionType["TransactionOverLimit"] = "transactionOverLimit";
})(PromotionType = exports.PromotionType || (exports.PromotionType = {}));
class Promotion {
    constructor(data) {
        this.data = data;
    }
    getOrderLevelDiscountReward() {
        const discountReward = {
            "promotionId": this.data.promotionId,
            "discounts": _.cloneDeep(this.data.discounts)
        };
        return discountReward;
    }
    getItemLevelDiscountReward(quantity) {
        let discountReward = this.getOrderLevelDiscountReward();
        discountReward.discounts.forEach((discount) => {
            if (discount.quantity.unitType === "GENERAL_SALES_QUANTITY") {
                discount.quantity.units = 1;
            }
            else {
                discount.quantity.units = quantity;
            }
        });
        return discountReward;
    }
    requiresRewardApproval() {
        return this.data.rewardApproval && Object.keys(this.data.rewardApproval).length > 0;
    }
    requiresPrompt() {
        return this.data.prompts && Object.keys(this.data.prompts).length > 0;
    }
    isApproved(approvals) {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "APPROVE";
    }
    isRejected(approvals) {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "REJECT";
    }
    isApplicable(items) {
        // Check whether discount match the rules requirements 
        if ((this.data.rules == undefined) || (this.data.rules.requires == undefined)) {
            return false;
        }
        let has_category_codes = (this.data.rules.requires.categoryCodes != undefined) &&
            (this.data.rules.requires.categoryCodes.length > 0);
        let has_item_codes = (this.data.rules.requires.itemCodes != undefined) &&
            (this.data.rules.requires.itemCodes.length > 0);
        // Do not continue if the promotion does not have a valid rules for either item or category codes
        if (!has_category_codes && !has_item_codes) {
            return false;
        }
        let satisfies = false;
        if (!satisfies && has_category_codes) {
            // Check whether some of the category codes has a match with items in transaction
            satisfies = this.data.rules.requires.categoryCodes.some((codes) => {
                return codes.every((code) => {
                    return items.some((item) => {
                        return (item.discountable === true && item.categoryCode === code);
                    });
                });
            });
        }
        if (!satisfies && has_item_codes) {
            // Check whether some of the item codes has a match with items in transaction
            satisfies = this.data.rules.requires.itemCodes.some((codes) => {
                return codes.every((code) => {
                    return items.some((item) => {
                        return (item.discountable === true && item.itemCode === code);
                    });
                });
            });
        }
        return satisfies;
    }
    getType() {
        return this.data.type;
    }
}
class ItemPromotion extends Promotion {
}
exports.ItemPromotion = ItemPromotion;
class OrderPromotion extends Promotion {
}
exports.OrderPromotion = OrderPromotion;
class BasicItemPromotion extends ItemPromotion {
    isApplicableToTransactionItem(item) {
        let has_category_codes = (this.data.rules.appliesTo.categoryCodes != undefined) &&
            (this.data.rules.appliesTo.categoryCodes.length > 0);
        let has_item_codes = (this.data.rules.appliesTo.itemCodes != undefined) &&
            (this.data.rules.appliesTo.itemCodes.length > 0);
        // Do not continue if the promotion does not have a valid rules for either item or category codes
        if (!has_category_codes && !has_item_codes) {
            return false;
        }
        let satisfies = false;
        if (!satisfies && has_category_codes) {
            // Check whether some of the category code has a match with item
            satisfies = this.data.rules.appliesTo.categoryCodes.some((code) => {
                return (item.categoryCode === code);
            });
        }
        if (!satisfies && has_item_codes) {
            // Check whether some of the item code has a match with item
            satisfies = this.data.rules.appliesTo.itemCodes.some((code) => {
                return (item.itemCode === code);
            });
        }
        return satisfies;
    }
}
exports.BasicItemPromotion = BasicItemPromotion;
class BasicOrderPromotion extends OrderPromotion {
}
exports.BasicOrderPromotion = BasicOrderPromotion;
class TransactionOverLimitPromotion extends OrderPromotion {
    isApplicable(items) {
        // Do not continue if the promotion does not have a valid rules
        if (!this.data.rules || !this.data.rules.limit) {
            return false;
        }
        let total = items.reduce((acc, item) => {
            return acc + item.unitPrice * item.quantity.units;
        }, 0);
        return total >= this.data.rules.limit;
    }
}
exports.TransactionOverLimitPromotion = TransactionOverLimitPromotion;
//# sourceMappingURL=Promotions.js.map
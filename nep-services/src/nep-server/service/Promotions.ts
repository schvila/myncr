'use strict';

const _ = require("lodash");

export enum PromotionType {
    BasicItem = "basicItem",
    BasicOrder = "basicOrder",
    TransactionOverLimit = "transactionOverLimit"
}

export interface IPromotion {
    data: any;
    isApplicable(items: any): boolean;
    getOrderLevelDiscountReward(): any;
    getItemLevelDiscountReward(quantity: number): any;
    requiresRewardApproval(): boolean;
    isApproved(approvals: Map<string, string>): boolean;
    isRejected(approvals: Map<string, string>): boolean;
    getType(): PromotionType;
}

abstract class Promotion implements IPromotion {
    data: any;
    constructor(data: any) {
        this.data = data;
    }

    getOrderLevelDiscountReward(): any {
        const discountReward = {
            "promotionId": this.data.promotionId,
            "discounts" :  _.cloneDeep(this.data.discounts)
        };
        return discountReward;
    }
	
	getItemLevelDiscountReward(quantity: number): any {
		let discountReward = this.getOrderLevelDiscountReward();
		discountReward.discounts.forEach((discount: any) => {
            if (discount.quantity.unitType === "GALLON_US_LIQUID" || discount.quantity.unitType === "GENERAL_SALES_QUANTITY")
            {
                discount.quantity.units = 1;
            }
            else {
                discount.quantity.units = quantity;
            }
        });

		return discountReward;
	}

    requiresRewardApproval(): boolean {
        return this.data.rewardApproval && Object.keys(this.data.rewardApproval).length > 0;
    }

    isApproved(approvals: Map<string, string>): boolean {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "APPROVE";
    }
    
    isRejected(approvals: Map<string, string>): boolean {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "REJECT";
    }

    isApplicable(items: any): boolean {
        // Do not continue if the promotion does not have a valid trigger
        if (!this.data.trigger || !this.data.trigger.matchingItems || !this.data.trigger.matchingItems.length) {
            return false;
        }

        // Check whether all category codes of the trigger are in the basket
        for (let matchingItem of this.data.trigger.matchingItems) {
            let includes = items.some((item: any) => {
                return item.categoryCode === matchingItem.categoryCode;
            });

            if (!includes) {
                return false;
            }
        }

        return true;
    }

    getType(): PromotionType {
        return this.data.type;
    }
}

export abstract class ItemPromotion extends Promotion {
    abstract isApplicableToTransactionItem(item: any): boolean;
}

export abstract class OrderPromotion extends Promotion {
}

export class BasicItemPromotion extends ItemPromotion {
    isApplicableToTransactionItem(item: any): boolean {
        return this.data.trigger.matchingItems[0].categoryCode === item.categoryCode;
    }
}

export class BasicOrderPromotion extends OrderPromotion {
}

export class TransactionOverLimitPromotion extends OrderPromotion {
    isApplicable(items: any): boolean {
        // Do not continue if the promotion does not have a valid trigger
        if (!this.data.trigger || !this.data.trigger.limit) {
            return false;
        }
        
        let total: number = items.reduce((acc: number, item: any) => {
            return acc + item.unitPrice * item.quantity.units;
        }, 0);

        return total >= this.data.trigger.limit;
    }
}
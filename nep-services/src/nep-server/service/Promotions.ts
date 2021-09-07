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
    requiresPrompt(): boolean;
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
            if (discount.quantity.unitType === "GENERAL_SALES_QUANTITY") {
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

    requiresPrompt(): boolean {
        return this.data.prompts && Object.keys(this.data.prompts).length > 0;
    }

    isApproved(approvals: Map<string, string>): boolean {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "APPROVE";
    }
    
    isRejected(approvals: Map<string, string>): boolean {
        return approvals.has(this.data.promotionId) && approvals.get(this.data.promotionId) === "REJECT";
    }

    isApplicable(items: any): boolean {
        // Check whether discount match the rules requirements 
        if ((this.data.rules == undefined) || (this.data.rules.requires == undefined)) 
        {
            return false;
        }

        let has_category_codes = (this.data.rules.requires.categoryCodes != undefined) && 
                                 (this.data.rules.requires.categoryCodes.length > 0);
        let has_item_codes = (this.data.rules.requires.itemCodes != undefined) && 
                             (this.data.rules.requires.itemCodes.length > 0);

        // Do not continue if the promotion does not have a valid rules for either item or category codes
        if (!has_category_codes && !has_item_codes)
        {
            return false;
        }

        let satisfies = false;
        
        if (!satisfies && has_category_codes)
        {
            // Check whether some of the category codes has a match with items in transaction
            satisfies = this.data.rules.requires.categoryCodes.some((codes: any) => 
            {
                return codes.every((code: string) => 
                {
                    return items.some((item: any) => 
                    {
                        return (item.discountable === true && item.categoryCode === code);
                    });
                });
            });
        }

        if (!satisfies && has_item_codes)
        {
            // Check whether some of the item codes has a match with items in transaction
            satisfies = this.data.rules.requires.itemCodes.some((codes: any) => 
            {
                return codes.every((code: string) => 
                {
                    return items.some((item: any) => 
                    {
                        return (item.discountable === true && item.itemCode === code);
                    });
                });
            });
        }

        return satisfies;
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
        let has_category_codes = (this.data.rules.appliesTo.categoryCodes != undefined) && 
                                 (this.data.rules.appliesTo.categoryCodes.length > 0);
        let has_item_codes = (this.data.rules.appliesTo.itemCodes != undefined) && 
                             (this.data.rules.appliesTo.itemCodes.length > 0);

        // Do not continue if the promotion does not have a valid rules for either item or category codes
        if (!has_category_codes && !has_item_codes)
        {
            return false;
        }

        let satisfies = false;

        if (!satisfies && has_category_codes)
        {
            // Check whether some of the category code has a match with item
            satisfies = this.data.rules.appliesTo.categoryCodes.some((code: string) => 
            {
                return (item.categoryCode === code);
            });
        }

        if (!satisfies && has_item_codes)
        {
            // Check whether some of the item code has a match with item
            satisfies = this.data.rules.appliesTo.itemCodes.some((code: string) => 
            {
                return (item.itemCode === code);
            });
        }

        return satisfies;
    }
}

export class BasicOrderPromotion extends OrderPromotion {
}

export class TransactionOverLimitPromotion extends OrderPromotion {
    isApplicable(items: any): boolean {
        // Do not continue if the promotion does not have a valid rules
        if (!this.data.rules || !this.data.rules.limit) {
            return false;
        }
        
        let total: number = items.reduce((acc: number, item: any) => {
            return acc + item.unitPrice * item.quantity.units;
        }, 0);

        return total >= this.data.rules.limit;
    }
}
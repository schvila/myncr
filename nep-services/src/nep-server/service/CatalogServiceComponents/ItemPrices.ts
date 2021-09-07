'use strict';

import * as express from 'express'
import * as _ from 'lodash'
import { catalogVersion, logger } from '../CatalogService'
import { SnapshotManager, IVersionedItem } from './SnapshotManager'
import { skipIfDummyMode, getMandatoryHeader, checkServiceAPIVersionIsCorrect } from '../ServiceCommon'

let baseUrl = '/catalog/:version/item-prices/:minorVersion';

interface IPriceId {
    itemCode: string;
    enterpriseUnitId: string;
    priceCode: string;
}

function getPriceIdAsString(priceId) {
    return `${priceId.itemCode}-${priceId.enterpriseUnitId}-${priceId.priceCode}`;
}

class ItemPrice implements IVersionedItem {
    version: number;
    priceId: IPriceId;

    constructor(obj) {
        if (typeof obj.version !== 'number') {
            throw Error('Invalid version number. Cannot process item.');
        }

        Object.assign(this, obj);
    }

    getId() {
        return getPriceIdAsString(this.priceId);
    }

    getItemVersion() {
        return this.version;
    }
}

let catalogServiceItemPricesMap = new Map<string, ItemPrice>();
let snapshotManager = new SnapshotManager<ItemPrice>();

export function clearItemPrices() {
    snapshotManager.clear();
    catalogServiceItemPricesMap.clear();
}

function getSnapshotItems() {
    return Array.from(catalogServiceItemPricesMap.values());
}

function addItemPricesToCatalog(itemPriceToAdd: ItemPrice) {
    const existingItemPrice = catalogServiceItemPricesMap.get(itemPriceToAdd.getId());

    if (existingItemPrice === undefined || existingItemPrice === null || existingItemPrice.version < itemPriceToAdd.version) {
        logger.log('silly', `Adding or updating item: ${itemPriceToAdd.priceId.itemCode} to catalog`);
        catalogServiceItemPricesMap.set(itemPriceToAdd.getId(), itemPriceToAdd);
    } else {
        logger.log('info', `Preconditions not satisfied, item ${itemPriceToAdd.priceId.itemCode} will not be added to catalog`);
    }
}

export function initializeRoutes(app: any, simulatorContext: any) {
    app.put(`${baseUrl}`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', `Adding or updating ${request.body['itemPrices'].length} item prices to catalog`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response)

            request.body['itemPrices'].forEach(x => addItemPricesToCatalog(new ItemPrice(x)));

            snapshotManager.takeSnapshot(getSnapshotItems());

            response.status(204).end();
        });

    app.post(`${baseUrl}/get-multiple`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);

            logger.log('info', `Trying to retrieve multiple item-prices for enterprise unit ${enterpriseUnit}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response)

            const result = { itemPrices: [] };

            for (let itemCode of request.body['itemIds']) {
                const existingItemPrices = _.filter(getSnapshotItems(), { priceId: { itemCode: itemCode.itemCode, enterpriseUnitId: enterpriseUnit } });
                existingItemPrices.forEach(x => { result.itemPrices.push(x); });
            }

            response.json(result);
        });

    app.get(`${baseUrl}/snapshot`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const snapshotVersion = parseInt(request.headers['nep-snapshot-version'] as string) || 0;

            logger.log('info', `Trying to retrieve item-prices for snapshot version ${snapshotVersion}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            snapshotManager.populateSnapshotResponse(snapshotVersion, () => true, request, response);
        });

    app.get(`${baseUrl}/:itemCode/:priceCode`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const itemCode: string = request.params['itemCode'];
            const priceCode: string = request.params['priceCode'];
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);
            logger.log('info', `Trying to get item-price for itemCode ${itemCode}, priceCode ${priceCode} and enterpriceUnit: ${enterpriseUnit}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            const existingItemPrice = catalogServiceItemPricesMap.get(getPriceIdAsString({ itemCode: itemCode, priceCode: priceCode, enterpriseUnitId: enterpriseUnit }));

            if (existingItemPrice == undefined) {
                response.json({
                    "details": ['itemPrice', itemCode, 'identifier'],
                    "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                    "message": `The itemPrice resource with the identifier '${itemCode}' does not exist.`,
                    "statusCode": 404
                });
            } else {
                response.json(existingItemPrice);
            }
        });

    app.put(`${baseUrl}/:itemCode/:priceCode`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const itemCode: string = request.params['itemCode'];
            const priceCode: string = request.params['priceCode'];
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);

            logger.log('info', `Trying to add item-price for itemCode ${itemCode} and priceCode ${priceCode}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response)

            const incomingItemPrice = new ItemPrice(request.body);

            if (_.has(incomingItemPrice, 'priceId')) {
                response.json({
                    errorType: 'com.ncr.nep.common.exception.BusinessException',
                    message:
                        'Unrecognized field "priceId" (class com.ncr.ocp.catalog.price.ItemPriceData), not marked as ignorable (9 known properties: "linkGroupId", "currency", "status", "effectiveDate", "dynamicAttributes", "version", "price", "endDate", "basePrice"])\n at [Source: org.apache.cxf.transport.http.AbstractHTTPDestination$1@6d71fc3d; line: 17, column: 17] (through reference chain: com.ncr.ocp.catalog.price.ItemPriceData["priceId"])',
                    statusCode: 400
                });
            } else {
                incomingItemPrice.priceId =
                    { itemCode: itemCode, enterpriseUnitId: enterpriseUnit, priceCode: priceCode };
                addItemPricesToCatalog(incomingItemPrice);

                snapshotManager.takeSnapshot(getSnapshotItems());

                response.status(204).end();
            }
        });
}
'use strict';

import * as express from 'express';
import { catalogVersion, logger } from '../CatalogService'
import { SnapshotManager, IVersionedItem } from './SnapshotManager'
import { skipIfDummyMode, getMandatoryHeader, checkServiceAPIVersionIsCorrect } from '../ServiceCommon'

let baseUrl = '/catalog/:version/item-attributes/:minorVersion';

interface IItemAttributesId {
    itemCode: string;
    enterpriseUnitId: string;
}

class ItemAttribute implements IVersionedItem {
    version: number;
    itemAttributesId: IItemAttributesId;

    constructor(obj) {
        if (typeof obj.version !== 'number') {
            throw Error('Invalid version number. Cannot process item.');
        }

        Object.assign(this, obj);
    }

    getId() {
        return this.itemAttributesId.itemCode;
    }

    getItemVersion() {
        return this.version;
    }
}

interface IItemAttributes {
    itemAttributes: ItemAttribute[];
}

let catalogServiceItemAttributesMap = new Map<string, ItemAttribute>();

let snapshotManager = new SnapshotManager<ItemAttribute>();

export function clearItemAttributes() {
    snapshotManager.clear();
    catalogServiceItemAttributesMap.clear();
}

function getKey(x: IItemAttributesId) {
    return `itemCode: ${x.itemCode} EU: ${x.enterpriseUnitId}`;
}

function getSnapshotItems() {
    return Array.from(catalogServiceItemAttributesMap.values());
}

function addItemAttributeToCatalog(itemAttributeToAdd: ItemAttribute) {
    const key = getKey(itemAttributeToAdd.itemAttributesId);
    const existingItemAttribute = catalogServiceItemAttributesMap.get(key);

    if (existingItemAttribute === undefined ||
        existingItemAttribute === null ||
        existingItemAttribute.version < itemAttributeToAdd.version) {
        logger.log('silly', `Adding or updating item: ${itemAttributeToAdd.itemAttributesId.itemCode} to catalog`);
        catalogServiceItemAttributesMap.set(key, itemAttributeToAdd);
    } else {
        logger.log('info', `Preconditions not satisfied, item ${itemAttributeToAdd.itemAttributesId.itemCode} will not be added to catalog`);
    }
}

export function initializeRoutes(app: any, simulatorContext: any) {
    app.put(baseUrl,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', `Adding or updating ${request.body['itemAttributes'].length} item attributes to catalog`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            request.body['itemAttributes'].forEach(x => addItemAttributeToCatalog(new ItemAttribute(x)));

            snapshotManager.takeSnapshot(getSnapshotItems());

            response.status(204).end();
        });

    app.post(`${baseUrl}/get-multiple`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);
            logger.log('info', `Trying to retrieve multiple item-attributes for enterprise unit ${enterpriseUnit}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            const result: IItemAttributes = { itemAttributes: [] };

            for (let itemId of request.body['itemIds']) {
                const key = getKey({ itemCode: itemId['itemCode'].toString(), enterpriseUnitId: enterpriseUnit });
                if (catalogServiceItemAttributesMap.has(key)) {
                    result.itemAttributes.push(catalogServiceItemAttributesMap.get(key));
                }
            }

            response.json(result);
        });

    app.get(`${baseUrl}/snapshot`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);
            const snapshotVersion = parseInt(request.headers['nep-snapshot-version'] as string) || 0;

            logger.log('info', `Trying to retrieve item-attributes for enterprise unit ${enterpriseUnit}, snapshot version ${snapshotVersion}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            snapshotManager.populateSnapshotResponse(snapshotVersion, x => {
                return x.itemAttributesId.enterpriseUnitId === enterpriseUnit;
            }, request, response);
        });

    app.get(`${baseUrl}/:itemCode`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const itemCode: string = request.params['itemCode'];
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);
            logger.log('info', `Trying to get item-attribute for itemCode ${itemCode} and enterprise unit ${enterpriseUnit}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            const key = getKey({ itemCode: itemCode, enterpriseUnitId: enterpriseUnit });

            if (catalogServiceItemAttributesMap.has(key)) {
                response.json(catalogServiceItemAttributesMap.get(key));
            } else {
                response.status(404).json({
                    "details": ['ItemAttributes', itemCode, 'identifier'],
                    "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                    "message": `The ItemAttributes resource with the identifier '${itemCode}' does not exist.`,
                    "statusCode": 404
                });
            }
        });

    app.put(`${baseUrl}/:itemCode`,
        skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const itemCode: string = request.params['itemCode'];
            const enterpriseUnit = getMandatoryHeader('nep-enterprise-unit', request, response);

            logger.log('info', `Trying to add item-attribute for itemCode ${itemCode} and enterprise unit ${enterpriseUnit}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            const incomingItemAttribute = new ItemAttribute(request.body);
            incomingItemAttribute.itemAttributesId = { itemCode: itemCode, enterpriseUnitId: enterpriseUnit };
            addItemAttributeToCatalog(incomingItemAttribute);

            snapshotManager.takeSnapshot(getSnapshotItems());

            response.status(204).end();
        });
}
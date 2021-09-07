'use strict';

import * as express from 'express';
import { catalogVersion, logger } from '../CatalogService';
import { SnapshotManager, IVersionedItem } from './SnapshotManager'
import { skipIfDummyMode, checkServiceAPIVersionIsCorrect } from '../ServiceCommon'

let baseUrl = '/catalog/:version/items/:minorVersion';

interface IItemId {
    itemCode: string;
}

class CatalogItem implements IVersionedItem {
    version: number;
    itemId: IItemId;

    constructor(obj) {
        if (typeof obj.version !== 'number') {
            throw Error('Invalid version number. Cannot process item.');
        }

        Object.assign(this, obj);
    }

    getId() {
        return this.itemId.itemCode;
    }

    getItemVersion() {
        return this.version;
    }
}

let catalogItems: CatalogItem[] = [];

let snapshotManager = new SnapshotManager<CatalogItem>();

function addItemToCatalog(element: CatalogItem): void {
    logger.log('silly', `Adding item ${element.itemId.itemCode} to catalog`);
    catalogItems.push(element);
}

function updateItemInCatalog(element: CatalogItem): void {
    const itemCode = element.itemId.itemCode;
    const itemIndex = findItemIndexInCatalog(itemCode);
    logger.log('info', `Updating item ${itemCode} in catalog`);
    catalogItems[itemIndex] = element;
}

function findItemIndexInCatalog(itemCode: string): number {
    return catalogItems.findIndex((element): boolean => element.itemId.itemCode === itemCode);
}

function createNullErrorResponse(response: express.Response, path: string): void {
    response.status(400).json({
        "message": `[The value 'null' is invalid for the path ${path}: may not be null]`,
        "errorType": 'com.ncr.nep.common.exception.PayloadConstraintViolationException',
        "details": []
    });
}

function isValidItem(response: express.Response, element): boolean {
    let error = false;
    if(typeof element.itemId === 'undefined') {
        createNullErrorResponse(response, 'items[].ItemId');
        error = true;
    } else if(typeof element.itemId.itemCode === 'undefined') {
        createNullErrorResponse(response, 'items[].ItemId.itemCode');
        error = true;
    }

    return !error;
}

function isValidItemBatch(request: express.Request, response: express.Response): boolean {
    let error = false;

    for (let element of request.body['items']) {
        if (!isValidItem(response, element)) {
            error = true;
            break;
        }
    }

    return !error;
}

function updateItem(request: express.Request, response: express.Response, itemCode: string): void {
    const element = request.body;
    element.itemId = { "itemCode": itemCode };
    const availableInCatalog = findItemIndexInCatalog(itemCode) !== -1;

    if (availableInCatalog) {
        updateItemInCatalog(element);
    } else {
        addItemToCatalog(new CatalogItem(element));
    }

    response.status(204).end();
}

function updateItemBatch(request: express.Request, response: express.Response): void {
    request.body['items'].forEach(element => {
        const itemCode: string = element.itemId.itemCode;
        const availableInCatalog = findItemIndexInCatalog(itemCode) !== -1;

        if (availableInCatalog) {
            logger.log('info', `Ignoring item ${itemCode} - already in catalog`);
        } else {
            addItemToCatalog(new CatalogItem(element));
        }
    });

    response.status(204).end();
}

export function initializeRoutes(app: any, simulatorContext: any) {
    app.get(`${baseUrl}`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', 'Getting items from catalog');
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            response.json({
                "lastPage": true,
                "pageNumber": 0,
                "totalPages": catalogItems.length > 0 ? 1 : 0,
                "totalResults": catalogItems.length,
                "pageContent": catalogItems
            });
        }
    );

    app.get(`${baseUrl}/snapshot`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            const snapshotVersion = parseInt(request.headers['nep-snapshot-version'] as string) || 0;

            logger.log('info', `Getting snapshot of items from catalog for snapshot version ${snapshotVersion}`);
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            snapshotManager.populateSnapshotResponse(snapshotVersion, () => true, request, response);
        }
    );

    app.get(`${baseUrl}/suggestions`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', 'Getting suggestions of items from catalog');
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

            const suggestionItems: CatalogItem[] = [];
            const descriptionIdentifier = request.query.descriptionPattern;
            const packageIdentifier = request.query.packageIdentifierPattern;
            const merchandiseIdentifier = request.query.merchandiseCategoryId;
            const codeIdentifier = request.query.codePattern;

            for (let element of catalogItems) {
                let added : boolean = false;
                if (descriptionIdentifier !== undefined) {
                    for(let d of element['longDescription'].values) {
                        if (d['value'].includes(descriptionIdentifier)) {
                            suggestionItems.push(element);
                            added = true;
                        }
                    }
                }

                if (!added && descriptionIdentifier !== undefined) {
                    for(let d of element['shortDescription'].values) {
                        if (d['value'].includes(descriptionIdentifier)) {
                            suggestionItems.push(element);
                        }
                    }
                }

                if (!added && packageIdentifier !== undefined) {
                    for(let d of element['packageIdentifiers']) {
                        if (d['value'].includes(packageIdentifier)) {
                            suggestionItems.push(element);
                        }
                    }
                }

                if (!added && merchandiseIdentifier !== undefined) {
                    if (element['merchandiseCategory']['nodeId'] === merchandiseIdentifier) {
                        suggestionItems.push(element);
                    }
                }

                if (!added && codeIdentifier !== undefined) {
                    if (element.itemId.itemCode.includes(codeIdentifier)) {
                        suggestionItems.push(element);
                    }
                }
            }

            response.json({ "lastPage": false,
                "pageNumber": 0,
                "totalPages": suggestionItems.length > 0 ? 1: 0,
                "totalResults": suggestionItems.length,
                "snapshotVersion": (new Date).getTime(),
                "pageContent" : suggestionItems });
        }
    );

    app.get(`${baseUrl}/:itemCode`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', 'Getting item from catalog');
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);
            const itemCode: string = request.params['itemCode'];
            const itemIndex = findItemIndexInCatalog(itemCode);
            if (itemIndex === -1) {
                response.status(404).json({
                    "message": `The Item resource with the identifier ${itemCode} does not exist.`,
                    "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                    "details": []
                });
            }
            else
            {
                response.json(catalogItems[itemIndex]);
            }
        }
    );

    app.put(`${baseUrl}`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', 'Updating items in catalog');
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);
            if (isValidItemBatch(request, response)) {
                updateItemBatch(request, response);
                snapshotManager.takeSnapshot(catalogItems);
            }
        }
    );

    app.put(`${baseUrl}/:itemCode`, skipIfDummyMode(simulatorContext),
        (request: express.Request, response: express.Response): void => {
            logger.log('info', 'Updating item in catalog');
            checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);
            const itemCode: string = request.params['itemCode'];
            updateItem(request, response, itemCode);
            snapshotManager.takeSnapshot(catalogItems);
        }
    );
}

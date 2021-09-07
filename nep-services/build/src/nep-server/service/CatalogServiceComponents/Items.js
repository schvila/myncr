'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const CatalogService_1 = require("../CatalogService");
const SnapshotManager_1 = require("./SnapshotManager");
const ServiceCommon_1 = require("../ServiceCommon");
let baseUrl = '/catalog/:version/items/:minorVersion';
class CatalogItem {
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
let catalogItems = [];
let snapshotManager = new SnapshotManager_1.SnapshotManager();
function addItemToCatalog(element) {
    CatalogService_1.logger.log('silly', `Adding item ${element.itemId.itemCode} to catalog`);
    catalogItems.push(element);
}
function updateItemInCatalog(element) {
    const itemCode = element.itemId.itemCode;
    const itemIndex = findItemIndexInCatalog(itemCode);
    CatalogService_1.logger.log('info', `Updating item ${itemCode} in catalog`);
    catalogItems[itemIndex] = element;
}
function findItemIndexInCatalog(itemCode) {
    return catalogItems.findIndex((element) => element.itemId.itemCode === itemCode);
}
function createNullErrorResponse(response, path) {
    response.status(400).json({
        "message": `[The value 'null' is invalid for the path ${path}: may not be null]`,
        "errorType": 'com.ncr.nep.common.exception.PayloadConstraintViolationException',
        "details": []
    });
}
function isValidItem(response, element) {
    let error = false;
    if (typeof element.itemId === 'undefined') {
        createNullErrorResponse(response, 'items[].ItemId');
        error = true;
    }
    else if (typeof element.itemId.itemCode === 'undefined') {
        createNullErrorResponse(response, 'items[].ItemId.itemCode');
        error = true;
    }
    return !error;
}
function isValidItemBatch(request, response) {
    let error = false;
    for (let element of request.body['items']) {
        if (!isValidItem(response, element)) {
            error = true;
            break;
        }
    }
    return !error;
}
function updateItem(request, response, itemCode) {
    const element = request.body;
    element.itemId = { "itemCode": itemCode };
    const availableInCatalog = findItemIndexInCatalog(itemCode) !== -1;
    if (availableInCatalog) {
        updateItemInCatalog(element);
    }
    else {
        addItemToCatalog(new CatalogItem(element));
    }
    response.status(204).end();
}
function updateItemBatch(request, response) {
    request.body['items'].forEach(element => {
        const itemCode = element.itemId.itemCode;
        const availableInCatalog = findItemIndexInCatalog(itemCode) !== -1;
        if (availableInCatalog) {
            CatalogService_1.logger.log('info', `Ignoring item ${itemCode} - already in catalog`);
        }
        else {
            addItemToCatalog(new CatalogItem(element));
        }
    });
    response.status(204).end();
}
function initializeRoutes(app, simulatorContext) {
    app.get(`${baseUrl}`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', 'Getting items from catalog');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        response.json({
            "lastPage": true,
            "pageNumber": 0,
            "totalPages": catalogItems.length > 0 ? 1 : 0,
            "totalResults": catalogItems.length,
            "pageContent": catalogItems
        });
    });
    app.get(`${baseUrl}/snapshot`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const snapshotVersion = parseInt(request.headers['nep-snapshot-version']) || 0;
        CatalogService_1.logger.log('info', `Getting snapshot of items from catalog for snapshot version ${snapshotVersion}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        snapshotManager.populateSnapshotResponse(snapshotVersion, () => true, request, response);
    });
    app.get(`${baseUrl}/suggestions`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', 'Getting suggestions of items from catalog');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const suggestionItems = [];
        const descriptionIdentifier = request.query.descriptionPattern;
        const packageIdentifier = request.query.packageIdentifierPattern;
        const merchandiseIdentifier = request.query.merchandiseCategoryId;
        const codeIdentifier = request.query.codePattern;
        for (let element of catalogItems) {
            let added = false;
            if (descriptionIdentifier !== undefined) {
                for (let d of element['longDescription'].values) {
                    if (d['value'].includes(descriptionIdentifier)) {
                        suggestionItems.push(element);
                        added = true;
                    }
                }
            }
            if (!added && descriptionIdentifier !== undefined) {
                for (let d of element['shortDescription'].values) {
                    if (d['value'].includes(descriptionIdentifier)) {
                        suggestionItems.push(element);
                    }
                }
            }
            if (!added && packageIdentifier !== undefined) {
                for (let d of element['packageIdentifiers']) {
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
            "totalPages": suggestionItems.length > 0 ? 1 : 0,
            "totalResults": suggestionItems.length,
            "snapshotVersion": (new Date).getTime(),
            "pageContent": suggestionItems });
    });
    app.get(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', 'Getting item from catalog');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const itemCode = request.params['itemCode'];
        const itemIndex = findItemIndexInCatalog(itemCode);
        if (itemIndex === -1) {
            response.status(404).json({
                "message": `The Item resource with the identifier ${itemCode} does not exist.`,
                "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                "details": []
            });
        }
        else {
            response.json(catalogItems[itemIndex]);
        }
    });
    app.put(`${baseUrl}`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', 'Updating items in catalog');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        if (isValidItemBatch(request, response)) {
            updateItemBatch(request, response);
            snapshotManager.takeSnapshot(catalogItems);
        }
    });
    app.put(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', 'Updating item in catalog');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const itemCode = request.params['itemCode'];
        updateItem(request, response, itemCode);
        snapshotManager.takeSnapshot(catalogItems);
    });
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=Items.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const _ = require("lodash");
const CatalogService_1 = require("../CatalogService");
const SnapshotManager_1 = require("./SnapshotManager");
const ServiceCommon_1 = require("../ServiceCommon");
let baseUrl = '/catalog/:version/item-prices/:minorVersion';
function getPriceIdAsString(priceId) {
    return `${priceId.itemCode}-${priceId.enterpriseUnitId}-${priceId.priceCode}`;
}
class ItemPrice {
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
let catalogServiceItemPricesMap = new Map();
let snapshotManager = new SnapshotManager_1.SnapshotManager();
function clearItemPrices() {
    snapshotManager.clear();
    catalogServiceItemPricesMap.clear();
}
exports.clearItemPrices = clearItemPrices;
function getSnapshotItems() {
    return Array.from(catalogServiceItemPricesMap.values());
}
function addItemPricesToCatalog(itemPriceToAdd) {
    const existingItemPrice = catalogServiceItemPricesMap.get(itemPriceToAdd.getId());
    if (existingItemPrice === undefined || existingItemPrice === null || existingItemPrice.version < itemPriceToAdd.version) {
        CatalogService_1.logger.log('silly', `Adding or updating item: ${itemPriceToAdd.priceId.itemCode} to catalog`);
        catalogServiceItemPricesMap.set(itemPriceToAdd.getId(), itemPriceToAdd);
    }
    else {
        CatalogService_1.logger.log('info', `Preconditions not satisfied, item ${itemPriceToAdd.priceId.itemCode} will not be added to catalog`);
    }
}
function initializeRoutes(app, simulatorContext) {
    app.put(`${baseUrl}`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', `Adding or updating ${request.body['itemPrices'].length} item prices to catalog`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        request.body['itemPrices'].forEach(x => addItemPricesToCatalog(new ItemPrice(x)));
        snapshotManager.takeSnapshot(getSnapshotItems());
        response.status(204).end();
    });
    app.post(`${baseUrl}/get-multiple`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to retrieve multiple item-prices for enterprise unit ${enterpriseUnit}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const result = { itemPrices: [] };
        for (let itemCode of request.body['itemIds']) {
            const existingItemPrices = _.filter(getSnapshotItems(), { priceId: { itemCode: itemCode.itemCode, enterpriseUnitId: enterpriseUnit } });
            existingItemPrices.forEach(x => { result.itemPrices.push(x); });
        }
        response.json(result);
    });
    app.get(`${baseUrl}/snapshot`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const snapshotVersion = parseInt(request.headers['nep-snapshot-version']) || 0;
        CatalogService_1.logger.log('info', `Trying to retrieve item-prices for snapshot version ${snapshotVersion}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        snapshotManager.populateSnapshotResponse(snapshotVersion, () => true, request, response);
    });
    app.get(`${baseUrl}/:itemCode/:priceCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const itemCode = request.params['itemCode'];
        const priceCode = request.params['priceCode'];
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to get item-price for itemCode ${itemCode}, priceCode ${priceCode} and enterpriceUnit: ${enterpriseUnit}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const existingItemPrice = catalogServiceItemPricesMap.get(getPriceIdAsString({ itemCode: itemCode, priceCode: priceCode, enterpriseUnitId: enterpriseUnit }));
        if (existingItemPrice == undefined) {
            response.json({
                "details": ['itemPrice', itemCode, 'identifier'],
                "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                "message": `The itemPrice resource with the identifier '${itemCode}' does not exist.`,
                "statusCode": 404
            });
        }
        else {
            response.json(existingItemPrice);
        }
    });
    app.put(`${baseUrl}/:itemCode/:priceCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const itemCode = request.params['itemCode'];
        const priceCode = request.params['priceCode'];
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to add item-price for itemCode ${itemCode} and priceCode ${priceCode}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const incomingItemPrice = new ItemPrice(request.body);
        if (_.has(incomingItemPrice, 'priceId')) {
            response.json({
                errorType: 'com.ncr.nep.common.exception.BusinessException',
                message: 'Unrecognized field "priceId" (class com.ncr.ocp.catalog.price.ItemPriceData), not marked as ignorable (9 known properties: "linkGroupId", "currency", "status", "effectiveDate", "dynamicAttributes", "version", "price", "endDate", "basePrice"])\n at [Source: org.apache.cxf.transport.http.AbstractHTTPDestination$1@6d71fc3d; line: 17, column: 17] (through reference chain: com.ncr.ocp.catalog.price.ItemPriceData["priceId"])',
                statusCode: 400
            });
        }
        else {
            incomingItemPrice.priceId =
                { itemCode: itemCode, enterpriseUnitId: enterpriseUnit, priceCode: priceCode };
            addItemPricesToCatalog(incomingItemPrice);
            snapshotManager.takeSnapshot(getSnapshotItems());
            response.status(204).end();
        }
    });
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=ItemPrices.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const CatalogService_1 = require("../CatalogService");
const SnapshotManager_1 = require("./SnapshotManager");
const ServiceCommon_1 = require("../ServiceCommon");
let baseUrl = '/catalog/:version/item-attributes/:minorVersion';
class ItemAttribute {
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
let catalogServiceItemAttributesMap = new Map();
let snapshotManager = new SnapshotManager_1.SnapshotManager();
function clearItemAttributes() {
    snapshotManager.clear();
    catalogServiceItemAttributesMap.clear();
}
exports.clearItemAttributes = clearItemAttributes;
function getKey(x) {
    return `itemCode: ${x.itemCode} EU: ${x.enterpriseUnitId}`;
}
function getSnapshotItems() {
    return Array.from(catalogServiceItemAttributesMap.values());
}
function addItemAttributeToCatalog(itemAttributeToAdd) {
    const key = getKey(itemAttributeToAdd.itemAttributesId);
    const existingItemAttribute = catalogServiceItemAttributesMap.get(key);
    if (existingItemAttribute === undefined ||
        existingItemAttribute === null ||
        existingItemAttribute.version < itemAttributeToAdd.version) {
        CatalogService_1.logger.log('silly', `Adding or updating item: ${itemAttributeToAdd.itemAttributesId.itemCode} to catalog`);
        catalogServiceItemAttributesMap.set(key, itemAttributeToAdd);
    }
    else {
        CatalogService_1.logger.log('info', `Preconditions not satisfied, item ${itemAttributeToAdd.itemAttributesId.itemCode} will not be added to catalog`);
    }
}
function initializeRoutes(app, simulatorContext) {
    app.put(baseUrl, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        CatalogService_1.logger.log('info', `Adding or updating ${request.body['itemAttributes'].length} item attributes to catalog`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        request.body['itemAttributes'].forEach(x => addItemAttributeToCatalog(new ItemAttribute(x)));
        snapshotManager.takeSnapshot(getSnapshotItems());
        response.status(204).end();
    });
    app.post(`${baseUrl}/get-multiple`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to retrieve multiple item-attributes for enterprise unit ${enterpriseUnit}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const result = { itemAttributes: [] };
        for (let itemId of request.body['itemIds']) {
            const key = getKey({ itemCode: itemId['itemCode'].toString(), enterpriseUnitId: enterpriseUnit });
            if (catalogServiceItemAttributesMap.has(key)) {
                result.itemAttributes.push(catalogServiceItemAttributesMap.get(key));
            }
        }
        response.json(result);
    });
    app.get(`${baseUrl}/snapshot`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        const snapshotVersion = parseInt(request.headers['nep-snapshot-version']) || 0;
        CatalogService_1.logger.log('info', `Trying to retrieve item-attributes for enterprise unit ${enterpriseUnit}, snapshot version ${snapshotVersion}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        snapshotManager.populateSnapshotResponse(snapshotVersion, x => {
            return x.itemAttributesId.enterpriseUnitId === enterpriseUnit;
        }, request, response);
    });
    app.get(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const itemCode = request.params['itemCode'];
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to get item-attribute for itemCode ${itemCode} and enterprise unit ${enterpriseUnit}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const key = getKey({ itemCode: itemCode, enterpriseUnitId: enterpriseUnit });
        if (catalogServiceItemAttributesMap.has(key)) {
            response.json(catalogServiceItemAttributesMap.get(key));
        }
        else {
            response.status(404).json({
                "details": ['ItemAttributes', itemCode, 'identifier'],
                "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                "message": `The ItemAttributes resource with the identifier '${itemCode}' does not exist.`,
                "statusCode": 404
            });
        }
    });
    app.put(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (request, response) => {
        const itemCode = request.params['itemCode'];
        const enterpriseUnit = ServiceCommon_1.getMandatoryHeader('nep-enterprise-unit', request, response);
        CatalogService_1.logger.log('info', `Trying to add item-attribute for itemCode ${itemCode} and enterprise unit ${enterpriseUnit}`);
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
        const incomingItemAttribute = new ItemAttribute(request.body);
        incomingItemAttribute.itemAttributesId = { itemCode: itemCode, enterpriseUnitId: enterpriseUnit };
        addItemAttributeToCatalog(incomingItemAttribute);
        snapshotManager.takeSnapshot(getSnapshotItems());
        response.status(204).end();
    });
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=ItemAttributes.js.map
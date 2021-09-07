'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const ServiceCommon_1 = require("./ServiceCommon");
let logger = wl.init('ItemAvailabilityService');
let baseUrl = '/ias/:version/item-availability/1';
let itemAvailabilityNotificationsTopic = 'ias_availability_changed_topic';
let itemAvailabilityVersion = 1;
let unavailableItems = [];
function itemUnavailable(itemCode, enterpriseUnitId) {
    const itemRecord = unavailableItems.find((element) => element['itemCode'] === itemCode);
    if (!itemRecord) {
        unavailableItems.push({
            "itemCode": itemCode,
            "enterpriseUnitId": enterpriseUnitId
        });
    }
}
function itemAvailable(itemCode) {
    const itemRecord = unavailableItems.find((element) => element['itemCode'] === itemCode);
    if (itemRecord) {
        unavailableItems.splice(unavailableItems.indexOf(itemRecord), 1);
    }
}
function sendItemAvailabilityUpdatedNotification(simulatorContext, newlyAvailableItems, newlyUnavailableItems) {
    const payload = {
        "newlyAvailableItems": newlyAvailableItems,
        "newlyUnavailableItems": newlyUnavailableItems
    };
    simulatorContext.sendMessageToAllNotificationClients(itemAvailabilityNotificationsTopic, JSON.stringify(payload));
}
function initializeRoutes(app, simulatorContext) {
    app.get(baseUrl, ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Getting bulk item availability');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);
        res.json({
            "lastPage": true,
            "pageNumber": 0,
            "totalPages": unavailableItems.length > 0 ? 1 : 0,
            "totalResults": unavailableItems.length,
            "pageContent": unavailableItems
        });
    });
    app.get(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Getting item availability');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);
        const itemCode = req.params['itemCode'];
        let availableForSale = true;
        if (unavailableItems.find((element) => element['itemCode'] === itemCode)) {
            availableForSale = false;
        }
        res.json({ "availableForSale": availableForSale });
    });
    app.put(`${baseUrl}/:itemCode`, ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Updating item availability');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);
        const itemCode = req.params['itemCode'];
        const availableForSale = req.body['availableForSale'];
        if (availableForSale) {
            itemAvailable(itemCode);
            sendItemAvailabilityUpdatedNotification(simulatorContext, [itemCode], undefined);
        }
        else {
            itemUnavailable(itemCode, (req.headers['nep-enterprise-unit']));
            sendItemAvailabilityUpdatedNotification(simulatorContext, undefined, [itemCode]);
        }
        res.json({});
    });
    app.put(baseUrl, ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Updating item availability');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);
        const itemAvailabilityUpdate = req.body;
        const itemAvailabilityData = itemAvailabilityUpdate['multiItemAvailabilityWriteData'];
        const enterpriseUnitId = (req.headers['nep-enterprise-unit']);
        const newlyAvailableItems = itemAvailabilityData.filter(element => element['availableForSale']).map(element => element['itemCode']);
        const newlyUnavailableItems = itemAvailabilityData.filter(element => !element['availableForSale']).map(element => element['itemCode']);
        newlyAvailableItems.forEach(itemCode => itemAvailable(itemCode));
        newlyUnavailableItems.forEach(itemCode => itemUnavailable(itemCode, enterpriseUnitId));
        sendItemAvailabilityUpdatedNotification(simulatorContext, newlyAvailableItems, newlyUnavailableItems);
        res.json({});
    });
    app.delete(baseUrl, ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', 'Updating item availability');
        ServiceCommon_1.checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);
        unavailableItems = [];
        res.json({});
    });
}
exports.initializeRoutes = initializeRoutes;
;
//# sourceMappingURL=ItemAvailabilityService.js.map
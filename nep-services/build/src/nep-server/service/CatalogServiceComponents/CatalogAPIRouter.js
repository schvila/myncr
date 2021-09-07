"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ServiceCommon_1 = require("../ServiceCommon");
const CatalogService_1 = require("../CatalogService");
// helper class to quick start supporting new APIs with basic functionalities
class CatalogAPIRouter {
    constructor(app, simulatorContext, versionedItemManager) {
        this.app = app;
        this.simulatorContext = simulatorContext;
        this.versionedItemManager = versionedItemManager;
    }
    setupAddMultipleRoute(url, extractItems) {
        this.app.put(url, ServiceCommon_1.skipIfDummyMode(this.simulatorContext), (request, response) => {
            CatalogService_1.logger.log('info', `Addding or updating multiple items to catalog`);
            ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
            this.versionedItemManager.addMultiple(extractItems(request));
            response.status(204).end();
        });
    }
    setupAddSingleRoute(url, extractItem) {
        this.app.put(url, ServiceCommon_1.skipIfDummyMode(this.simulatorContext), (request, response) => {
            CatalogService_1.logger.log('info', `Adding single item to catalog`);
            ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
            this.versionedItemManager.addSingle(extractItem(request));
            response.status(204).end();
        });
    }
    setupGetSnapshotRoute(url) {
        this.app.get(url, ServiceCommon_1.skipIfDummyMode(this.simulatorContext), (request, response) => {
            CatalogService_1.logger.log('info', `Returning snapshot`);
            ServiceCommon_1.checkServiceAPIVersionIsCorrect(CatalogService_1.catalogVersion, request.params['version'], response);
            this.versionedItemManager.getSnapshot(request, response);
        });
    }
}
exports.CatalogAPIRouter = CatalogAPIRouter;
//# sourceMappingURL=CatalogAPIRouter.js.map
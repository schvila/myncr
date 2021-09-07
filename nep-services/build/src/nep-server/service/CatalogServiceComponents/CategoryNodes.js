'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const CatalogAPIRouter_1 = require("./CatalogAPIRouter");
const VersionedItemManager_1 = require("./VersionedItemManager");
let baseUrl = '/catalog/:version/category-nodes/:minorVersion';
class CategoryNode {
    constructor(obj, nodeId) {
        if (typeof obj.version !== 'number') {
            throw Error('Invalid version number. Cannot process item.');
        }
        Object.assign(this, obj);
        if (nodeId) {
            this.nodeId = { nodeId: nodeId };
        }
    }
    getId() {
        return this.nodeId.nodeId;
    }
    getItemVersion() {
        return this.version;
    }
}
let categoryNodeManager = new VersionedItemManager_1.VersionedItemManager();
function initializeRoutes(app, simulatorContext) {
    let catalogAPIRouter = new CatalogAPIRouter_1.CatalogAPIRouter(app, simulatorContext, categoryNodeManager);
    catalogAPIRouter.setupAddMultipleRoute(baseUrl, (request) => request.body['nodes'].map(x => new CategoryNode(x)));
    catalogAPIRouter.setupGetSnapshotRoute(`${baseUrl}/snapshot`);
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=CategoryNodes.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const VersionedItemManager_1 = require("./VersionedItemManager");
const CatalogAPIRouter_1 = require("./CatalogAPIRouter");
let baseUrl = '/catalog/:version/link-groups/:minorVersion';
class LinkGroup {
    constructor(obj, linkGroupCode) {
        if (typeof obj.version !== 'number') {
            throw Error('Invalid version number. Cannot process item.');
        }
        Object.assign(this, obj);
        if (linkGroupCode) {
            this.linkGroupId = { linkGroupCode: linkGroupCode };
        }
    }
    getId() {
        return this.linkGroupId.linkGroupCode;
    }
    getItemVersion() {
        return this.version;
    }
}
let linkGroupManager = new VersionedItemManager_1.VersionedItemManager();
function initializeRoutes(app, simulatorContext) {
    let catalogAPIHelper = new CatalogAPIRouter_1.CatalogAPIRouter(app, simulatorContext, linkGroupManager);
    catalogAPIHelper.setupAddMultipleRoute(baseUrl, (request) => request.body['linkGroups'].map(x => new LinkGroup(x)));
    catalogAPIHelper.setupAddSingleRoute(`${baseUrl}/:linkGroupCode`, (request) => new LinkGroup(request.body, request.params['linkGroupCode']));
    catalogAPIHelper.setupGetSnapshotRoute(`${baseUrl}/snapshot`);
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=LinkGroups.js.map
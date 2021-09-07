"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const SnapshotManager_1 = require("./SnapshotManager");
const CatalogService_1 = require("../CatalogService");
class VersionedItemManager {
    constructor() {
        this.versionedItemsMap = new Map();
        this.snapshotManager = new SnapshotManager_1.SnapshotManager();
    }
    addVersionedItemToCatalog(versionedItem) {
        const key = versionedItem.getId();
        const existingItem = this.versionedItemsMap.get(key);
        if (existingItem == null || existingItem.version < versionedItem.getItemVersion()) {
            CatalogService_1.logger.log('silly', `Adding or updating item ${versionedItem.getId()} to catalog`);
            this.versionedItemsMap.set(key, versionedItem);
        }
        else {
            CatalogService_1.logger.log('info', `Precondition not satisfied, item ${versionedItem.getId()} will not be added to catalog`);
        }
    }
    takeSnapshot() {
        this.snapshotManager.takeSnapshot(Array.from(this.versionedItemsMap.values()));
    }
    addMultiple(versionedItems) {
        versionedItems.forEach(this.addVersionedItemToCatalog.bind(this));
        this.takeSnapshot();
    }
    addSingle(linkGroup) {
        this.addVersionedItemToCatalog(linkGroup);
        this.takeSnapshot();
    }
    getSnapshot(request, response) {
        this.snapshotManager.populateSnapshotResponse(parseInt(request.headers['nep-snapshot-version']) || 0, () => true, request, response);
    }
}
exports.VersionedItemManager = VersionedItemManager;
//# sourceMappingURL=VersionedItemManager.js.map
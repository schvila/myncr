'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const bounds = require("binary-search-bounds");
const StorageService = require("../StorageService");
class SnapshotManager {
    constructor() {
        this.clear();
    }
    clear() {
        this.snapshots = [];
        this.takeSnapshot([]);
    }
    takeSnapshot(snapshotItems) {
        this.snapshotItems = snapshotItems;
        this.snapshots.push({
            snapshotVersion: Date.now(),
            itemsVersion: new Map(this.snapshotItems.map(x => [x.getId(), x.getItemVersion()]))
        });
    }
    populateSnapshotResponse(snapshotVersion, filterItems, request, response) {
        let startIndex = bounds.le(this.snapshots, { snapshotVersion: snapshotVersion }, (a, b) => {
            return a.snapshotVersion - b.snapshotVersion;
        });
        if (startIndex < 0) {
            startIndex = 0;
        }
        const startSnapshot = this.snapshots[startIndex];
        const endSnapshot = this.snapshots[this.snapshots.length - 1];
        const snapshotItems = this.snapshotItems
            .filter(filterItems)
            .filter(x => {
            const id = x.getId();
            if (!startSnapshot.itemsVersion.has(id) ||
                startSnapshot.itemsVersion.get(id) < endSnapshot.itemsVersion.get(id)) {
                return true;
            }
            return false;
        });
        StorageService.processContent({
            snapshotVersion: endSnapshot.snapshotVersion,
            snapshot: snapshotItems
        }, snapshotItems.length, request, response);
    }
}
exports.SnapshotManager = SnapshotManager;
//# sourceMappingURL=SnapshotManager.js.map
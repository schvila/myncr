import { IVersionedItem, SnapshotManager } from "./SnapshotManager";
import { logger } from "../CatalogService";

export class VersionedItemManager<TVersionedItem extends IVersionedItem> {
    private versionedItemsMap;
    private snapshotManager;

    private addVersionedItemToCatalog(versionedItem: TVersionedItem) {
        const key = versionedItem.getId();
        const existingItem = this.versionedItemsMap.get(key);

        if (existingItem == null || existingItem.version < versionedItem.getItemVersion()) {
            logger.log('silly', `Adding or updating item ${versionedItem.getId()} to catalog`);
            this.versionedItemsMap.set(key, versionedItem);
        } else {
            logger.log('info', `Precondition not satisfied, item ${versionedItem.getId()} will not be added to catalog`);
        }
    }

    private takeSnapshot() {
        this.snapshotManager.takeSnapshot(Array.from(this.versionedItemsMap.values()));
    }

    public constructor() {
        this.versionedItemsMap = new Map<string, TVersionedItem>();
        this.snapshotManager = new SnapshotManager<TVersionedItem>();
    }

    public addMultiple(versionedItems: TVersionedItem[]) {
        versionedItems.forEach(this.addVersionedItemToCatalog.bind(this));
        this.takeSnapshot();
    }

    public addSingle(linkGroup) {
        this.addVersionedItemToCatalog(linkGroup);
        this.takeSnapshot();
    }

    public getSnapshot(request, response) {
        this.snapshotManager.populateSnapshotResponse(parseInt(request.headers['nep-snapshot-version'] as string) || 0, () => true, request, response);
    }
}
'use strict';

import { CatalogAPIRouter } from './CatalogAPIRouter';
import { IVersionedItem } from './SnapshotManager';
import { VersionedItemManager } from './VersionedItemManager';

let baseUrl = '/catalog/:version/category-nodes/:minorVersion';

interface INodeId {
    nodeId: string;
}

class CategoryNode implements IVersionedItem {
    version: number;
    nodeId: INodeId;

    constructor(obj, nodeId?) {
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

let categoryNodeManager = new VersionedItemManager<CategoryNode>();

export function initializeRoutes(app: any, simulatorContext: any) {
    let catalogAPIRouter = new CatalogAPIRouter(app, simulatorContext, categoryNodeManager);
    catalogAPIRouter.setupAddMultipleRoute(baseUrl, (request) => request.body['nodes'].map(x => new CategoryNode(x)));
    catalogAPIRouter.setupGetSnapshotRoute(`${baseUrl}/snapshot`);
}
'use strict';

import { IVersionedItem } from './SnapshotManager';
import { VersionedItemManager } from './VersionedItemManager';
import { CatalogAPIRouter } from './CatalogAPIRouter';

let baseUrl = '/catalog/:version/link-groups/:minorVersion';

interface ILinkGroupId {
    linkGroupCode: string;
}

class LinkGroup implements IVersionedItem {
    version: number;
    linkGroupId: ILinkGroupId;

    constructor(obj, linkGroupCode?) {
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

let linkGroupManager = new VersionedItemManager<LinkGroup>();

export function initializeRoutes(app: any, simulatorContext: any) {
    let catalogAPIHelper = new CatalogAPIRouter(app, simulatorContext, linkGroupManager);
    catalogAPIHelper.setupAddMultipleRoute(baseUrl, (request) => request.body['linkGroups'].map(x => new LinkGroup(x)));
    catalogAPIHelper.setupAddSingleRoute(`${baseUrl}/:linkGroupCode`, (request) => new LinkGroup(request.body, request.params['linkGroupCode']));
    catalogAPIHelper.setupGetSnapshotRoute(`${baseUrl}/snapshot`);
}
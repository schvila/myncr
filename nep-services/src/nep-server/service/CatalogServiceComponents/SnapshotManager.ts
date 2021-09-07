'use strict';

import bounds = require('binary-search-bounds')
import * as express from 'express'
import StorageService = require('../StorageService')

interface ISnapshot {
    snapshotVersion: number;
    itemsVersion: Map<string, number>;
}

export interface IVersionedItem {
    getId();
    getItemVersion();
}

export class SnapshotManager<TSnapshotItem extends IVersionedItem> {
    private snapshotItems: TSnapshotItem[];
    private snapshots: ISnapshot[]; // constraint: sorted by snapshotVersion

    constructor() {
        this.clear();
    }

    clear() {
        this.snapshots = [];
        this.takeSnapshot([]);
    }

    takeSnapshot(snapshotItems: TSnapshotItem[]) {
        this.snapshotItems = snapshotItems;
        this.snapshots.push({
            snapshotVersion: Date.now(),
            itemsVersion: new Map(this.snapshotItems.map(x => [x.getId(), x.getItemVersion()] as [string, number]))
        } as ISnapshot);
    }

    populateSnapshotResponse(snapshotVersion: number, filterItems, request: express.Request, response: express.Response) {
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
import { skipIfDummyMode, checkServiceAPIVersionIsCorrect } from "../ServiceCommon";
import express = require("express");
import { logger, catalogVersion } from "../CatalogService";

// helper class to quick start supporting new APIs with basic functionalities

export class CatalogAPIRouter {
    private app;
    private simulatorContext;
    private versionedItemManager;

    public constructor(app, simulatorContext, versionedItemManager) {
        this.app = app;
        this.simulatorContext = simulatorContext;
        this.versionedItemManager = versionedItemManager;
    }

    public setupAddMultipleRoute(url, extractItems) {
        this.app.put(url, skipIfDummyMode(this.simulatorContext),
            (request: express.Request, response: express.Response): void => {
                logger.log('info', `Addding or updating multiple items to catalog`);
                checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

                this.versionedItemManager.addMultiple(extractItems(request));

                response.status(204).end();
            }
        );
    }

    public setupAddSingleRoute(url, extractItem) {
        this.app.put(url, skipIfDummyMode(this.simulatorContext),
            (request: express.Request, response: express.Response): void => {
                logger.log('info', `Adding single item to catalog`);
                checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

                this.versionedItemManager.addSingle(extractItem(request));

                response.status(204).end();
            });
    }

    public setupGetSnapshotRoute(url) {
        this.app.get(url, skipIfDummyMode(this.simulatorContext),
            (request: express.Request, response: express.Response): void => {
                logger.log('info', `Returning snapshot`);
                checkServiceAPIVersionIsCorrect(catalogVersion, request.params['version'], response);

                this.versionedItemManager.getSnapshot(request, response);
            });
    }
}
'use strict';

import * as wl from '@config/winston';
import * as catalogItems from './CatalogServiceComponents/Items';
import * as catalogItemAttributes from './CatalogServiceComponents/ItemAttributes';
import * as catalogItemPrices from './CatalogServiceComponents/ItemPrices';
import * as catalogCategoryNodes from './CatalogServiceComponents/CategoryNodes';
import * as catalogLinkGroups from './CatalogServiceComponents/LinkGroups';

export let catalogVersion = 2;

export let logger = wl.init('CatalogService');

export function initializeRoutes(app: any, simulatorContext: any) {
    catalogItems.initializeRoutes(app, simulatorContext);
    catalogItemAttributes.initializeRoutes(app, simulatorContext);
    catalogItemPrices.initializeRoutes(app, simulatorContext);
    catalogCategoryNodes.initializeRoutes(app, simulatorContext);
    catalogLinkGroups.initializeRoutes(app, simulatorContext);
}
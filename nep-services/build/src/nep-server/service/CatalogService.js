'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const catalogItems = require("./CatalogServiceComponents/Items");
const catalogItemAttributes = require("./CatalogServiceComponents/ItemAttributes");
const catalogItemPrices = require("./CatalogServiceComponents/ItemPrices");
const catalogCategoryNodes = require("./CatalogServiceComponents/CategoryNodes");
const catalogLinkGroups = require("./CatalogServiceComponents/LinkGroups");
exports.catalogVersion = 2;
exports.logger = wl.init('CatalogService');
function initializeRoutes(app, simulatorContext) {
    catalogItems.initializeRoutes(app, simulatorContext);
    catalogItemAttributes.initializeRoutes(app, simulatorContext);
    catalogItemPrices.initializeRoutes(app, simulatorContext);
    catalogCategoryNodes.initializeRoutes(app, simulatorContext);
    catalogLinkGroups.initializeRoutes(app, simulatorContext);
}
exports.initializeRoutes = initializeRoutes;
//# sourceMappingURL=CatalogService.js.map
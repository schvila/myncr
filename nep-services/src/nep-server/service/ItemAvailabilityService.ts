'use strict';

import * as wl from '@config/winston';
import * as express from 'express';
import { skipIfDummyMode, checkServiceAPIVersionIsCorrect } from './ServiceCommon'
import { Context } from 'nep-server/simulator/Context';

let logger = wl.init('ItemAvailabilityService');
let baseUrl = '/ias/:version/item-availability/1';
let itemAvailabilityNotificationsTopic = 'ias_availability_changed_topic'
let itemAvailabilityVersion = 1;

interface IOdspItem {
    itemCode: string,
    enterpriseUnitId: string;
}

let unavailableItems: IOdspItem[] = [];

function itemUnavailable(itemCode: string, enterpriseUnitId: string): void {
    const itemRecord: IOdspItem = unavailableItems.find((element): boolean => element['itemCode'] === itemCode);

    if(!itemRecord)
    {
        unavailableItems.push({
            "itemCode": itemCode,
            "enterpriseUnitId": enterpriseUnitId
        });
    }
}

function itemAvailable(itemCode: string): void {
    const itemRecord = unavailableItems.find((element): boolean => element['itemCode'] === itemCode);

    if (itemRecord) {
        unavailableItems.splice(unavailableItems.indexOf(itemRecord), 1);
    }
}

function sendItemAvailabilityUpdatedNotification(simulatorContext: Context, newlyAvailableItems?: string[], newlyUnavailableItems?: string[]): void {
    const payload = {
        "newlyAvailableItems": newlyAvailableItems,
        "newlyUnavailableItems": newlyUnavailableItems
    };

    simulatorContext.sendMessageToAllNotificationClients(itemAvailabilityNotificationsTopic, JSON.stringify(payload));
}

export function initializeRoutes(app: any, simulatorContext: any);
export function initializeRoutes(app, simulatorContext: Context) {
    app.get(baseUrl, skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            logger.log('info', 'Getting bulk item availability');
            checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);

            res.json({
                "lastPage": true,
                "pageNumber": 0,
                "totalPages": unavailableItems.length > 0 ? 1 : 0,
                "totalResults": unavailableItems.length,
                "pageContent": unavailableItems
            });
        }
    );

    app.get(`${baseUrl}/:itemCode`, skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            logger.log('info', 'Getting item availability');
            checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);

            const itemCode: string = req.params['itemCode'];

            let availableForSale: boolean = true;
            if (unavailableItems.find((element): boolean => element['itemCode'] === itemCode)) {
                availableForSale = false;
            }

            res.json({ "availableForSale": availableForSale });
        }
    );

    app.put(`${baseUrl}/:itemCode`, skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            logger.log('info', 'Updating item availability');
            checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);

            const itemCode: string = req.params['itemCode'];
            const availableForSale:boolean = req.body['availableForSale'];

            if(availableForSale) {
                itemAvailable(itemCode);
                sendItemAvailabilityUpdatedNotification(simulatorContext, [itemCode], undefined )
            } else {
                itemUnavailable(itemCode, <string>(req.headers['nep-enterprise-unit']));
                sendItemAvailabilityUpdatedNotification(simulatorContext, undefined, [itemCode] )
            }

            res.json({});
        }
    );

    app.put(baseUrl, skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            logger.log('info', 'Updating item availability');
            checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);

            const itemAvailabilityUpdate = req.body;
            const itemAvailabilityData: any[] = itemAvailabilityUpdate['multiItemAvailabilityWriteData'];
            const enterpriseUnitId = <string>(req.headers['nep-enterprise-unit']);

            const newlyAvailableItems = itemAvailabilityData.filter(element => element['availableForSale']).map(element => element['itemCode']);
            const newlyUnavailableItems = itemAvailabilityData.filter(element => !element['availableForSale']).map(element => element['itemCode']);

            newlyAvailableItems.forEach(itemCode => itemAvailable(itemCode));
            newlyUnavailableItems.forEach(itemCode => itemUnavailable(itemCode, enterpriseUnitId));

            sendItemAvailabilityUpdatedNotification(simulatorContext, newlyAvailableItems, newlyUnavailableItems )

            res.json({});
        }
    );

    app.delete(baseUrl, skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            logger.log('info', 'Updating item availability');
            checkServiceAPIVersionIsCorrect(itemAvailabilityVersion, req.params['version'], res);

            unavailableItems = [];

            res.json({});
        }
    );
};

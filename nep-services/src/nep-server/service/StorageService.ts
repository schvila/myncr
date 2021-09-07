'use strict';

import * as wl from '@config/winston'
import * as express from 'express'
import * as fs from 'fs'
import * as shell from 'shelljs'
import * as randomString from 'randomstring'
import * as zlib from 'zlib'
import * as url from 'url'
import * as path from 'path'
import { skipIfDummyMode } from './ServiceCommon'

let logger = wl.init('StorageService');

const storagePathRelative = 'StorageData/';
const storageUrl = '/storage/storage-objects/';

export let miniBatchThreshold = 1000;
export let allowSaveFile = true;
export let username = "test_user";
export let organizationName = "org";

function getRelativeLocalPath(filename: string): string {
    return storagePathRelative + filename;
}

function generateRandomGZipFileName(): string {
    return randomString.generate({
        length: 8,
        charset: 'alphanumeric',
        capitalization: 'lowercase'
    }) + '.gz';
}

function createGZip(payload: string, filename:string){

    return new Promise(function(resolve, reject){
        if (allowSaveFile) {
            logger.log('info', `Writing file ${filename}`);
                    
            const gzipStream = zlib.createGzip();
            const fileStream = fs.createWriteStream(getRelativeLocalPath(filename));

            gzipStream.pipe(fileStream)
                .on("close", function (error) {
                    if (error)
                    {
                        reject();
                    }
                    else {
                        resolve();
                    }
                });
            gzipStream.write(payload);
            gzipStream.end();
        }
        else{
            resolve();
        }
        
    });
}

export function processContent(content: any, itemCount: number, request: express.Request, response: express.Response): void {
    if (itemCount <= miniBatchThreshold) {
        response.json(content);
    } else {
        var gzipFileName =  generateRandomGZipFileName();
        
        // TODO: return HTTP 409 if the file is currently being written to (do not block program flow until write is complete)
        // See BSP (ODSP) documentation:
        // https://dx-uat.swenglabs.ncr.com/portals/dev-portal/api-explorer/details/6/documentation?version=1.3.0-20190725154537-f3aa55a&path=get_storage-objects_containerName_objectName
        createGZip(JSON.stringify(content), gzipFileName)
            .then(function () {
                const link = url.resolve(`http://${request.headers.host}/`, storageUrl + gzipFileName);            

                response.status(409).json({
                    "details": [link],
                    "errorType": 'com.ncr.ocp.catalog.common.MaxPayloadSizeExceededException',
                    "message": `The number of changes that satisfy the request exceeds the maximum size. The request can be completed through the storage service under the following path: ${link}`,
                });
            });
    }
}


export function initializeRoutes(app: any, simulatorContext: any) {
    // make sure directory exists
    shell.mkdir('-p', storagePathRelative);
    // clean directory content
    shell.rm('-r', storagePathRelative + '/*');

    app.get(`/storage/storage-objects/:filename`,
        skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            const filename: string = req.params['filename'];
            
            logger.log('info', `Getting storage file ${filename}`);
            
            const filePath = getRelativeLocalPath(filename);
            try {
                var size = fs.statSync(filePath)["size"];
                res.header('Content-Length', size.toString());
                fs.createReadStream(filePath).pipe(res);
            }
            catch(err) {
                if (err['code'] === 'ENOENT') {
                    res.status(404).json({
                        "details": [
                            'Object',
                            filename,
                            'identifier'
                        ],
                        "errorType": 'com.ncr.nep.common.exception.ResourceDoesNotExistException',
                        "message": `The Object resource with the identifier '${filename}' does not exist.`
                    });
                }
                else {
                    throw err;
                }
            }
        });

    app.put(`/storage/storage-objects/:containerName/:filename`,
        skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {
            const filename: string = req.params['filename'];
            const dirname: string = req.params['containerName'];

            logger.log('info', `Saving a storage file ${filename}`);

            const filePath = getRelativeLocalPath(path.join(dirname, filename));

            let writeStream = fs.createWriteStream(filePath);
            logger.log('info', `Writing file ${dirname}/${filename}`);
            writeStream.end(Buffer.from(req.body));
            writeStream.on('error', err => {
                        throw err;
            });

            res.status(204).end();
        });

    // search for a storage container by name
    app.get(`/storage/storage-containers`,
        skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {

            logger.log('info', `Requested container name: ${req.query.namePattern}`);            

            if (fs.existsSync(path.join(storagePathRelative + req.query.namePattern))) {
                res.status(200).json({
                    "lastPage": true,
                    "pageNumber": 0,
                    "totalPages": 1,
                    "totalResults": 1,
                    "pageContent": [
                        {
                            "expirationPolicy": {
                                "hours": 0
                            },
                            "readPolicy": "ORGANIZATION",
                            "writePolicy": "ORGANIZATION",
                            "owner": {
                                "username": username,
                                "organizationName": organizationName
                            },
                            "containerId": {
                                "containerName": req.query.namePattern
                            }
                        }
                    ]
                })
            } else {
                res.status(200).json({
                    "lastPage": true,
                    "pageNumber": 0,
                    "totalPages": 0,
                    "totalResults": 0,
                    "pageContent": []
                });
            }
        });        
        
        // Create a new container
        app.post(`/storage/storage-containers`,
        skipIfDummyMode(simulatorContext),
        (req: express.Request, res: express.Response): void => {

            const containerName = req.body.containerId.containerName;
            const containerPath = path.join(storagePathRelative + containerName);

            if (fs.existsSync(containerPath)) {
                logger.log('warn', `Container ${containerName} already exists`);
                res.status(409).json({
                    "details": [
                        "Container",
                        `${containerName}`,
                        "identifier"
                    ],
                    "errorType": "com.ncr.nep.common.exception.ResourceAlreadyExistsException",
                    "message": `The Container resource with the identifier '${containerName}' already exists.`,
                    "statusCode": 409
                });
            } else {
                logger.log('info', `Creating container ${containerName}`);
                shell.mkdir("-p", containerPath);
                res.status(204).end();
            }
        });
}
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const wl = require("@config/winston");
const ServiceCommon_1 = require("./ServiceCommon");
const _ = require("lodash");
const xml2js = require("xml2js");
const path = require("path");
let logger = wl.init('RCMServerService');
let messages = [];
let fileMap = {};
let messageId = 1;
let siteTransformXml = '';
/**
 * @swagger
 *
 * components:
 *    schemas:
 *      DownloadRequest:
 *        type: object
 *        required:
 *          - siteId
 *          - updateId
 *        properties:
 *          siteId:
 *            type: string
 *          updateId:
 *            type: string
 */
function initializeRoutes(app, simulatorContext) {
    // Method to process a message from a client
    // This endpoint supports these messages:
    // - GetCurrentMessage
    // - CurrentAckSuccess
    // - CurrentNack
    /**
     * @swagger
     * /rcm/rsl-access-point:
     *  post:
     *      summary: Enqueue a new message
     *      tags:
     *          - rcm interface
     *      requestBody:
     *          description: Messaging XML. See https://confluence.ncr.com/display/pcrsc/Site+Host+Message+Interface for all supported messages
     *          required: true
     *          content:
     *              application/xml:
     *                  schema:
     *                      type: string
     *      responses:
     *          200:
     *              description: Success. Content will contain a message according to the interface specification.
     *                  See https://confluence.ncr.com/display/pcrsc/Site+Host+Message+Interface for more info.
     *              content:
     *                  application/xml:
     *                      schema:
     *                          type: string
     */
    app.post('/rcm/rsl-access-point', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', `Received RSLAccessPoint request`);
        var parser = new xml2js.Parser({
            explicitArray: false
        });
        let response = null;
        parser.parseString(req.body, (err, data) => {
            logger.log('info', `Parsing message request. Request: ${JSON.stringify(data)}`);
            const body = data["SOAP:Envelope"]["SOAP:Body"];
            if (body.GetCurrentMessage !== undefined) {
                logger.log('info', `Checking current message for site.`);
                const siteId = body.GetCurrentMessage.siteId;
                if (messages.length > 0) {
                    response = messages[0].response;
                }
                else {
                    logger.log('info', `No message to send`);
                    response = String.raw `<?xml version="1.0" encoding="utf-8"?>
                        <SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
                        <SOAP:Body>
                            <GetCurrentMessage>
                            <siteId>${siteId}</siteId>
                            <queueId />
                            </GetCurrentMessage>
                        </SOAP:Body>
                        </SOAP:Envelope>`;
                }
                res.type('application/xml');
                res.send(response);
            }
            else if (body.CurrentAckSuccess !== undefined) {
                if (messages.length > 0) {
                    const firstMessage = messages[0];
                    if (firstMessage.messageId.toString() === body.CurrentAckSuccess.msgId &&
                        firstMessage.siteId === body.CurrentAckSuccess.siteId) {
                        logger.log('info', `Received [OK acknowledgement] for the current message`);
                        res.type('application/xml');
                        res.status(200).send(req.body);
                        messages.pop();
                    }
                    else {
                        logger.log('error', `[OK Acknowledgement] failed because the current message has different siteId or messageId:`);
                        logger.log('error', `${firstMessage.messageId} vs ${body.CurrentAckSuccess.msgId}`);
                        logger.log('error', `${firstMessage.siteId} vs ${body.CurrentAckSuccess.siteId}`);
                        res.status(400).send(`[OK Acknowledgement] failed because the current message has different siteId or messageId`);
                    }
                }
                else {
                    logger.log('error', `[OK Acknowledgement] failed because there are no messages in queue`);
                    res.status(400).send(`[OK Acknowledgement] failed because there are no messages in queue`);
                }
            }
            else if (body.CurrentNack !== undefined) {
                if (messages.length > 0) {
                    const firstMessage = messages[0];
                    if (firstMessage.messageId.toString() === body.CurrentNack.msgId &&
                        firstMessage.siteId === body.CurrentNack.siteId) {
                        logger.log('info', `Received [Failed acknowledgement] for the current message`);
                        res.type('application/xml');
                        res.status(200).send(req.body);
                        messages.pop();
                    }
                    else {
                        logger.log('error', `[Failed Acknowledgement] failed because the current message has different siteId or messageId:`);
                        logger.log('error', `${firstMessage.messageId} vs ${body.CurrentNack.msgId}`);
                        logger.log('error', `${firstMessage.siteId} vs ${body.CurrentNack.siteId}`);
                        res.status(400).send(`[Failed Acknowledgement] failed because the current message has different siteId or messageId`);
                    }
                }
                else {
                    logger.log('error', `[Failed Acknowledgement] failed because there are no messages in queue`);
                    res.status(400).send(`[Failed Acknowledgement] failed because there are no messages in queue`);
                }
            }
            else {
                logger.log('error', `Unsupported message: ${JSON.stringify(body)}`);
                res.status(400).send(`Unsupported message`);
            }
        });
    });
    /**
     * @swagger
     * /RCMHostServices/File:
     *  get:
     *      summary: Downloads a file from RCM
     *      description: This requests attempts to download a file from RCM. It expects full path to the file.
     *      tags:
     *          - rcm
     *          - rcm interface
     *      parameters:
     *          - in: query
     *            name: fullpath
     *            schema:
     *                type: string
     *            required: true
     *            description: Full path to the file. (e.g. c:/rcmdata/Site_70000099/PFUpdate_70000099_70000015520.xml)
     *      responses:
     *          200:
     *              description: Success
     *              content:
     *                  application/octet-stream:
     *                      schema:
     *                          type: string
     *                          format: binary
     *              headers:
     *                  last-modified:
     *                      schema:
     *                          type: string
     *                      description: Last modified timestamp
     *          404:
     *              description: File not found
     */
    app.get('/RCMHostServices/File', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        let fileId = req.query.fullpath;
        if (fileId in fileMap) {
            const file = fileMap[fileId];
            if (file.lastModified !== undefined) {
                res.setHeader('last-modified', file.lastModified);
            }
            logger.log('info', `Sending file ${fileId} Last-Modified: ${file.lastModified || ''}`);
            res.type('application/octet-stream');
            res.status(200).send(file.content);
        }
        else {
            res.status(404).end();
        }
    });
    /**
     * @swagger
     * /rcm/site-transform:
     *  get:
     *      summary: Returns the currently stored site transform xsl
     *      description: This request requires version and appversion even though it is actually not used. But
     *          it matches the RCM interface.
     *      tags:
     *          - rcm
     *          - rcm interface
     *      parameters:
     *          - in: path
     *            name: version
     *            schema:
     *                type: string
     *            required: true
     *            description: version of the transformation. (e.g. v2019.2.206.0)
     *          - in: path
     *            name: appversion
     *            schema:
     *                type: string
     *            required: true
     *            description: app version of the transformation. (e.g. PCS-RPOS-G6)
     *      responses:
     *          200:
     *              description: Success
     *              content:
     *                  application/xml:
     *                      schema:
     *                          type: string
     */
    app.get('/rcm/site-transform', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        const version = req.query.version;
        const appVersion = req.query.appversion;
        if (version === undefined) {
            res.status(400).send('Missing version query parameter');
        }
        else if (appVersion === undefined) {
            res.status(400).send('Missing appversion query parameter');
        }
        else {
            logger.log('info', `Received request for site transform with version=${version} and appVersion=${appVersion}`);
            res.send(siteTransformXml).end();
        }
    });
    // ---------------------------------------------------
    // PRIVATE SIMULATOR METHODS
    //----------------------------------------------------
    /**
     * @swagger
     * /rcm/simulator/messages:
     *  post:
     *      summary: Enqueue a new message
     *      tags:
     *          - rcm
     *      parameters:
     *          - in: query
     *            name: siteId
     *            schema:
     *              type: string
     *            required: true
     *            description: Site id used to map the message to site
     *      requestBody:
     *          description: Entire XML message
     *          required: true
     *          content:
     *              application/xml:
     *                  schema:
     *                      type: string
     *      responses:
     *          204:
     *              description: Success
     */
    app.post('/rcm/simulator/messages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        messages.push({
            response: req.body,
            siteId: req.query.siteId,
            messageId: ++messageId
        });
        res.status(204).end();
    });
    /**
     * @swagger
     * /rcm/simulator/messages:
     *  delete:
     *      summary: Clears message queue
     *      tags:
     *          - rcm
     *      responses:
     *          204:
     *              description: Success
     */
    app.delete('/rcm/simulator/messages', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        messages = [];
        logger.log('info', `Deleted all messages`);
        res.status(204).end();
    });
    /**
     * @swagger
     * /rcm/simulator/messages/download-request:
     *  post:
     *      summary: Enqueue a new download request
     *      description: The message is constructed from all pre-configured files
     *      tags:
     *          - rcm
     *      requestBody:
     *          description: Must contain information necessary to build valid site download request
     *          required: true
     *          content:
     *              application/json:
     *                  schema:
     *                      $ref: '#/components/schemas/DownloadRequest'
     *      responses:
     *          200:
     *              description: Success
     *              content:
     *                  application/json:
     *                      schema:
     *                          type: object
     *                          properties:
     *                              messageId:
     *                                  type: integer
     *                                  description: Unique message id
     *
     */
    app.post('/rcm/simulator/messages/download-request', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        let siteId = req.body.siteId;
        let currentMessageId = ++messageId;
        let updateId = req.body.updateId;
        let downloadMessageXml = String.raw `<?xml version="1.0" encoding="utf-8"?>
                    <SOAP:Envelope xmlns:SOAP="http://schemas.xmlsoap.org/soap/envelope/">
                      <SOAP:Body>
                        <GetCurrentMessage>
                          <siteId>${siteId}</siteId>
                          <queueId />
                          <msgId>${currentMessageId}</msgId>
                          <xmlMsg>${makeDownloadXmlMessage(siteId, updateId)}</xmlMsg>
                        </GetCurrentMessage>
                      </SOAP:Body>
                    </SOAP:Envelope>`;
        messages.push({
            response: downloadMessageXml,
            siteId: siteId,
            messageId: currentMessageId
        });
        logger.log('info', `Created and enqueued download request messages`);
        res.status(200).send({ 'messageId': currentMessageId });
    });
    /**
     * @swagger
     * /rcm/simulator/files:
     *  post:
     *      summary: Prepare a file
     *      tags:
     *          - rcm
     *      parameters:
     *          - in: query
     *            name: fileId
     *            schema:
     *                type: string
     *            required: true
     *            description: File identifier. Usually full or relative path of file. When creating the download request the path
     *              is parsed and split into file name only and the rest to produce HostPath and FileName XML nodes.
     *          - in: query
     *            name: destFileName
     *            schema:
     *                type: string
     *            required: false
     *            description: Destination filename. This is used only for media files that should be stored on a particular location
     *              on Site Controller
     *          - in: query
     *            name: destPath
     *            schema:
     *                type: string
     *            required: false
     *            description: Destination path. This is used only for media files that should be stored on a particular location
     *              on Site Controller
     *          - in: header
     *            name: last-modified
     *            schema:
     *                type: string
     *            required: true
     *            description: File last modified timestamp in the standard format - Wed, 26 Jun 2019 15:17:31 GMT
     *      requestBody:
     *          description: File content
     *          required: true
     *          content:
     *              application/octet-stream:
     *                  schema:
     *                      type: string
     *                      format: binary
     *      responses:
     *          204:
     *              description: Success
     */
    app.post('/rcm/simulator/files', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        if ('last-modified' in req.headers) {
            let fileId = req.query.fileId;
            logger.log('info', `Received file ${fileId} Last-Modified: ${req.headers['last-modified']}`);
            fileMap[fileId] = {
                content: req.body,
                type: req.headers['content-type'],
                destFileName: req.query.destFileName,
                destPath: req.query.destPath,
                lastModified: req.headers['last-modified']
            };
            res.status(204).end();
        }
        else {
            res.status(400).send('Missing last-modified header field');
        }
    });
    /**
     * @swagger
     * /rcm/simulator/files:
     *  delete:
     *      summary: Deletes all prepared files
     *      tags:
     *          - rcm
     *      responses:
     *          204:
     *              description: Success
     */
    app.delete('/rcm/simulator/files', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        logger.log('info', `Clearing all files`);
        fileMap = {};
        res.status(204).end();
    });
    /**
     * @swagger
     * /rcm/simulator/site-transform:
     *  put:
     *      summary: Stores site transform xml file
     *      description: Site transform file will be used for rcm download request
     *      tags:
     *          - rcm
     *      requestBody:
     *          description: Site transform XML content
     *          required: true
     *          content:
     *              application/xml:
     *                  schema:
     *                      type: string
     *      responses:
     *          204:
     *              description: Success
     */
    app.put('/rcm/simulator/site-transform', ServiceCommon_1.skipIfDummyMode(simulatorContext), (req, res) => {
        siteTransformXml = req.body;
        res.status(204).end();
    });
}
exports.initializeRoutes = initializeRoutes;
;
function makeDownloadXmlMessage(siteId, updateId) {
    let files = '';
    for (const key in fileMap) {
        if (fileMap.hasOwnProperty(key)) {
            const parsedPath = path.parse(key);
            const fileDescription = fileMap[key];
            files += String.raw `
                <File>
                    <FileName>${parsedPath.base}</FileName>
                    <Type>${getFileType(fileDescription.type)}</Type>
                    <HostPath>${parsedPath.root}${parsedPath.dir}/</HostPath>
                    ${fileDescription.destFileName !== undefined ? '<DestName>' + fileDescription.destFileName + '</DestName>' : ''}
                    ${fileDescription.destPath !== undefined ? '<DestPath>' + fileDescription.destPath + '</DestPath>' : ''}
                </File>`;
        }
        ;
    }
    let xml = String.raw `<?xml version="1.0" encoding="utf-16"?>
    <SSDownloadFiles ManifestID="${updateId}">
        ${files}
    </SSDownloadFiles>`;
    return _.escape(xml);
}
function getFileType(contentType) {
    switch (contentType) {
        case 'application/xml':
        case 'text/xml':
            return 'XML';
        default:
            return 'Binary';
    }
}
//# sourceMappingURL=RCMServerService.js.map
'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
function skipIfDummyMode(simulatorContext) {
    return (req, res, next) => {
        if (simulatorContext.isDummyMode()) {
            return next('route');
        }
        else {
            return next();
        }
    };
}
exports.skipIfDummyMode = skipIfDummyMode;
function getMandatoryHeader(headerName, request, response) {
    const value = request.headers[headerName];
    if (value === undefined) {
        response.json({
            constraintViolations: {
                invalidValue: null, message: 'may not be null', propertyPath: headerName
            },
            details: [],
            errorType: 'com.ncr.nep.common.exception.PayloadConstraintViolationException',
            message: `[The value 'null' is invalid for the path '${headerName}': may not be null]`,
            statusCode: 400
        });
        throw Error(`Cannot continue without mandatory header ${headerName}`);
    }
    return value;
}
exports.getMandatoryHeader = getMandatoryHeader;
function checkServiceAPIVersionIsCorrect(majorVersion, versionString, response) {
    const versionRegExp = /^(\d)(\.\d+){0,2}$/;
    let matchResults = versionString.match(versionRegExp);
    if (matchResults === null) {
        response.json({
            "details": [],
            "errorType": 'com.ncr.platform.gateway.api.exception.InvalidServiceVersionException',
            "message": 'Invalid service version: The \'ncr-service-version\' value does not conform with the format {applicationVersion}:{serviceVersion} where version is a valid semantic version with an optional qualifier.',
            "statusCode": 404
        });
        throw Error(`The version string ${versionString} isn't validly formated as X.XX.XXX`);
    }
    if (matchResults[1] !== majorVersion.toString()) {
        response.json({
            "details": [],
            "errorType": 'com.ncr.platform.gateway.api.exception.ApiDoesNotExistException',
            "message": `The requested resource version ${versionString} does not exist.`,
            "statusCode": 404
        });
        throw Error(`The major version ${matchResults[0]} doesn't match the expected value ${majorVersion}`);
    }
}
exports.checkServiceAPIVersionIsCorrect = checkServiceAPIVersionIsCorrect;
//# sourceMappingURL=ServiceCommon.js.map
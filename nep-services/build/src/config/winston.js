'use strict';
Object.defineProperty(exports, "__esModule", { value: true });
const winston_1 = require("winston");
var options = {
    console: {
        level: 'debug',
        handleExceptions: true,
        json: false,
        colorize: true,
    },
};
const myFormat = winston_1.format.printf(info => {
    return `${info.timestamp} [${info.label}] ${info.level}: ${info.message}`;
});
function init(name) {
    const logger = winston_1.createLogger({
        format: winston_1.format.combine(winston_1.format.colorize(), winston_1.format.label({ 'label': name }), winston_1.format.timestamp(), myFormat),
        transports: [
            new winston_1.transports.Console(options.console)
        ],
        exitOnError: false,
    });
    logger.stream = {
        write: (message) => {
            logger.info(message);
        },
    };
    return logger;
}
exports.init = init;
;
//# sourceMappingURL=winston.js.map
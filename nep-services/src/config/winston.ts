'use strict';

import { format, createLogger, transports } from 'winston';

var options = {
    console: {
        level: 'debug',
        handleExceptions: true,
        json: false,
        colorize: true,
    },
};

const myFormat = format.printf(info => {
  return `${info.timestamp} [${info.label}] ${info.level}: ${info.message}`;
});


export function init(name: string) {
    const logger: any = createLogger({
        format: format.combine(
            format.colorize(),
            format.label({'label': name}),
            format.timestamp(),
            myFormat
        ),
        transports: [
            new transports.Console(options.console)
        ],
        exitOnError: false, // do not exit on handled exceptions
    });

    logger.stream = {
        write: (message: string) => {
            logger.info(message);
        },
    };

    return logger;
};

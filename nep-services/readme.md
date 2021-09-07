# SC HTTP Services Simulator

This simulator can be used as a replacement of any HTTP based service.

## Installation

```
npm install
```

## Run the simulator

```
npm start
```

## API Documentation

Start the simulator using `npm start` and open your browser at http://localhost:52345/api-docs
to see the API specification.

## Generate documentation

You can generate the documentation manually using `swagger-jsdoc` tool:

### Using local installation

Swagger jsdoc is required component of the simulator and so it should be already installed
if you have started the simulator. Otherwise see the Installation chapter.

```
.\node_modules\.bin\swagger-jsdoc -d .\src\openapi-def.js .\src\nep-server\service\RCMServerService.ts -o sc-simulator-api-swagger.json
```

### Using global installation

```
npm install swagger-jsdoc -g
swagger-jsdoc -d .\src\openapi-def.js .\src\nep-server\service\RCMServerService.ts -o sc-simulator-api-swagger.json
```

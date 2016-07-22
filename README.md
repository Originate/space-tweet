# Users Service

[![Circle CI](https://circleci.com/gh/Originate/exosphere-users-service.svg?style=shield&circle-token=b8da91b53c5b269eeb2460e344f521461ffe9895)](https://circleci.com/gh/Originate/exosphere-users-service)
[![Dependency Status](https://david-dm.org/originate/exosphere-users-service.svg)](https://david-dm.org/originate/exosphere-users-service)
[![devDependency Status](https://david-dm.org/originate/exosphere-users-service/dev-status.svg)](https://david-dm.org/originate/exosphere-users-service#info=devDependencies)
[![PNPM](https://img.shields.io/badge/pnpm-compatible-brightgreen.svg)](https://github.com/rstacruz/pnpm)


> An Exosphere service for storing user data




## Installation

* install ZeroMQ

  ```
  brew install zeromq
  ```

* install MongoDB

  ```
  brew install mongodb
  ```

* install dependencies

  ```
  npm install
  ```


## running

* start MongoDB

 ```
 mongod --config /usr/local/etc/mongod.conf
 ```

* start the service

  ```
  env EXOCOMM_PORT=4000 EXORELAY_PORT=4001 bin/start
  ```


## Development

See your [developer documentation](CONTRIBUTING.md)

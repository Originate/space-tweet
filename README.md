# Users Service [![Circle CI](https://circleci.com/gh/Originate/exosphere-users-service.svg?style=shield&circle-token=b8da91b53c5b269eeb2460e344f521461ffe9895)](https://circleci.com/gh/Originate/exosphere-users-service)
> An Exosphere service for storing user data




## Installation

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
  bin/start --exorelay-port 3000 --exocom-port 3100
  ```


## Development

See your [developer documentation](CONTRIBUTING.md)

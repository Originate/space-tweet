# Snippets Service [![Circle CI](https://circleci.com/gh/Originate/exosphere-snippets-service.svg?style=shield&circle-token=b8da91b53c5b269eeb2460e344f521461ffe9895)](https://circleci.com/gh/Originate/exosphere-snippets-service)
> An Exosphere service for storing snippets of data, which are associated to something

* snippets have
  * an owner
    - referenced by id.
    - its up to the application to know which domain classes are owners,
      locate a particular owner based on the given owner-id of a snippet,
      and understand what the snippet means to its owner.
  * content - text


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
  bin/start --exorelay-port 3000 --exocomm-port 3100
  ```


## Development

See your [developer documentation](CONTRIBUTING.md)

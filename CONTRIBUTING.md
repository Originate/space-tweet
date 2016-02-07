# Exosphere User Service Developer Guidelines

## Install

* `npm i`
* add `./bin/` to your PATH


## Development

* the CLI runs against the compiled JS, not the source LS,
  so run `watch` in a separate terminal to auto-compile changes


## Testing

```
bin/spec
```


## Update

```
david
```


## Deploy a new version

```
npm version <patch|minor|major>
npm publish
```

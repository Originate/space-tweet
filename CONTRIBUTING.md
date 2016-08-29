# Exosphere Mongo Service Developer Guidelines

## Install

* `npm i`
* add `./bin/` to your PATH


## Development

* the CLI runs against the compiled JS, not the source LS,
  so run `watch` in a separate terminal to auto-compile changes


## Testing

- don't run `build`, i.e. there should be no `dist` directory
- run all tests: `spec`
- run linter only: `lint`


## Update dependencies

```
$ update
```


## Deploy a new version

```
$ publish <patch|minor|major>
```

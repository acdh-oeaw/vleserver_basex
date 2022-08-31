# Server side API for VLE (web_dict_editor)

## Used specs

* API Problem [(RFC 7807)](https://tools.ietf.org/html/rfc7807)
* [JSON Hypertext Application Language](https://tools.ietf.org/html/draft-kelly-json-hal-08)

## Running the server

`docker run --rm -it -p 8984:5000 ghcr.io/acdh-oeaw/vleserver_basex`

## API spec

An automatically generated OpenAPI spec is available at `/restvle/openapi.json`
For example: `http://localhost:8984/restvle/openapi.json`
xquery version "3.1";

declare namespace _ = 'https://tools.ietf.org/html/draft-kelly-json-hal-00/test';
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at '../vleserver/json-hal.xqm';
import module namespace rest = "http://exquery.org/ns/restxq";

declare function _:test_create_list() {
   serialize(json-hal:create_document_list(static-base-uri(), static-base-uri(), static-base-uri(), (), 'dicts',
   [json-hal:create_document(xs:anyURI('/orders/1'), <sth type='object'/>), 
    json-hal:create_document(xs:anyURI('/orders/2'), <sth type='object'/>)], 1, 25, 1, 1), map {'method': 'json'})
};

_:test_create_list()
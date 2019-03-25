xquery version "3.1";

declare namespace _ = 'https://tools.ietf.org/html/draft-kelly-json-hal-00/test';
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at '../vleserver/json-hal.xqm';

declare function _:test_create_list() {
   serialize(json-hal:create_document_list(xs:anyURI('/orders'), xs:anyURI('/orders?page=2'), xs:anyURI('/orders{?id}'), 'orders',
   [json-hal:create_document(xs:anyURI('/orders/1'), xs:anyURI('/orders'), <sth type='object'/>), 
    json-hal:create_document(xs:anyURI('/orders/2'), xs:anyURI('/orders'), <sth type='object'/>)]), map {'method': 'json'})
};

_:test_create_list()
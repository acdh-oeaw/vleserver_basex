xquery version "3.1";

module namespace _ = 'https://tools.ietf.org/html/draft-kelly-json-hal-00';

import module namespace req = "http://exquery.org/ns/request";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";

declare variable $_:enable_trace external := true();

declare function _:create_link_object($href as xs:anyURI) as element()+ {
  (<href type='string'>{$href}</href>)
};

declare function _:create_document_list($_self as xs:anyURI, $_next as xs:anyURI, $_find as xs:anyURI, $_embedded_name as xs:string, $_embedded as array(element(json))) as element(json) {
   <json type='object' objects='__links __self __next __find __embedded'>
       <__links>
           <__self>{_:create_link_object($_self)}</__self>
           <__next>{_:create_link_object($_next)}</__next>
           <__find>{_:create_link_object($_find)}</__find>
       </__links>
       <__embedded> {
           element {$_embedded_name} {
               attribute {'type'} {'array'},
               $_embedded?*!<_>{./(@*|*)}</_>
           }
       }</__embedded>
       <took>0ms</took>
   </json>
};

declare function _:create_document($_self as xs:anyURI, $_collection as xs:anyURI, $data as element()+) {
  <json type='object'>
      <__links type='object'>
          <__self type='object'>{_:create_link_object($_self)}</__self>
          <__collection type='object'>{_:create_link_object($_collection)}</__collection>
      </__links>
      {$data}
  </json>
};
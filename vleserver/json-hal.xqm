xquery version "3.1";

module namespace _ = 'https://tools.ietf.org/html/draft-kelly-json-hal-00';

import module namespace req = "http://exquery.org/ns/request";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";

declare variable $_:enable_trace external := true();

declare function _:create_link_object($href as xs:anyURI) as element()+ {
  (<href type='string'>{$href}</href>)
};

declare function _:create_document_list($_self as xs:anyURI, $_embedded_name as xs:string, $_embedded as array(element(json)), $page_size as xs:integer, $total_items as xs:integer, $page as xs:integer) as element(json) {
  let $_self_with_parameters := if ($page = 1) 
        then xs:anyURI($_self||'?pageSize='||$page_size) 
        else xs:anyURI($_self||'?page='||$page||'&amp;pageSize='||$page_size),
      $last_page := xs:integer(ceiling($total_items div $page_size)),
      $_first := xs:anyURI($_self||'?page=1&amp;pageSize='||$page_size),
      $_last := xs:anyURI($_self||'?page='||$last_page||'&amp;pageSize='||$page_size),
      $_next := if ($page + 1 <= $last_page) then xs:anyURI($_self||'?page='||$page + 1||'&amp;pageSize='||$page_size)
  return
   <json type='object' objects='__links __self __first __last __next __embedded'>
       <__links>
           <__self>{_:create_link_object($_self_with_parameters)}</__self>
           <__first>{_:create_link_object($_first)}</__first>
           <__last>{_:create_link_object($_last)}</__last>
           { if ($_next) then <__next>{_:create_link_object($_next)}</__next> else () }
       </__links>
       <__embedded> {
           element {$_embedded_name} {
               attribute {'type'} {'array'},
               $_embedded?*!<_>{./(@*|*)}</_>
           }
       }</__embedded>
       <page__count>{$last_page}</page__count>
       <page__size>{$page_size}</page__size>
       <total__items>{$total_items}</total__items>
       <page>{$page}</page>
   </json>
};

declare function _:create_document($_self as xs:anyURI, $data as element()+) {
  <json type='object'>
      {$data}
      <__links type='object'>
          <__self type='object'>{_:create_link_object($_self)}</__self>
      </__links>
  </json>
};
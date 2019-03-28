xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/dicts';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)
import module namespace functx = "http://www.functx.com";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();

declare
    %rest:GET
    %rest:path('restvle/dicts')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDicts($pageSize as xs:integer, $page as xs:integer) {
  let $dicts := util:eval(``[db:list()[ends-with(., '__prof')]!replace(., '__prof', '')]``, (), 'get-list-of-profile'),
      $dicts_as_documents := $dicts!json-hal:create_document(xs:anyURI(rest:uri()||'/'||.), <name>{.}</name>)
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'dicts', array{$dicts_as_documents}, $pageSize, count($dicts), $page])
};

declare
    %rest:POST('{$data}') 
    %rest:path('restvle/dicts')
    %rest:header-param("Content-Type", "{$content-type}", "")
function _:createDict($data, $content-type as xs:string) {
  if ($content-type = 'application/json') then
    (: in this case $data is an element(json) :)
    if (exists($data/json/name)) then
      util:eval(``[
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
error(xs:QName('response-codes:_406'),
      'Dictionary "`{$data/json/name}`" already exists')
]``, (), 'try-create-dict')
    else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               'Need a { "name": "some_name" } object.&#x0a;'||
               'JSON was: '||serialize($data, map{'method': 'json'}))
  else 
    error(xs:QName('response-codes:_415'),
          'Content-Type needs to be application/json',
          'Content-Type was: '||$content-type)
};

(: Get dict_name -> ganzes dict, RFC 7233, Accept-Ranges: bytes, bytes für eine bestimmte Menge entries? :)

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}')
function _:getDictDictName($dict_name as xs:string) {
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/entries'), <note>all entries</note>),
    json-hal:create_document(xs:anyURI(rest:uri()||'/users'), <note>all users with access to this dictionary</note>)], 2, 2, 1])
};

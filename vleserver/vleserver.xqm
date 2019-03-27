xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";

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

(: Get dict_name -> ganzes dict, RFC 7233, Accept-Ranges: bytes, bytes für eine bestimmte Menge entries? :)

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}')
function _:getDictDictName($dict_name as xs:string) {
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/entries'), <note>all entries</note>),
    json-hal:create_document(xs:anyURI(rest:uri()||'/users'), <note>all users with access to this dictionary</note>)], 2, 2, 1])
};

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}/entries')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDictDictNameEntries($dict_name as xs:string, $pageSize as xs:integer, $page as xs:integer) {
  let $entries_ids := data-access:get-all-entries($dict_name)!(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/@xml:id
  };
]``) else ./@xml:id),
      $entries_as_documents := subsequence($entries_ids, (($page - 1) * $pageSize) + 1, $pageSize)!_:entryAsDocument(try {xs:anyURI(rest:uri()||'/'||data(.))} catch basex:http {xs:anyURI('urn:local')}, ., if ($pageSize <= 10) then data-access:get-entry-by-id($dict_name, .) else ())
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'entries', array{$entries_as_documents}, $pageSize, count($entries_ids), $page])
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as attribute(xml:id), $entry as element()?) {
  json-hal:create_document($_self, (
    <id>{data($id)}</id>,
    if (exists($entry)) then <entry>{serialize($entry)}</entry> else ()))
};

declare
   %rest:GET
   %rest:path('restvle/dicts/{$dict_name}/entries/{$id}')
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string) {
  let $entry := data-access:get-entry-by-id($dict_name, $id)
  return api-problem:or_result(_:entryAsDocument#3, [rest:uri(), $entry/@xml:id, $entry])
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
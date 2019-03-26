xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm'; 

declare namespace http = "http://expath.org/ns/http-client";

declare
    %rest:GET
    %rest:path('restvle/dicts')
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDicts($pageSize as xs:integer) {
  let $dicts := db:list()[ends-with(., '__prof')]!replace(., '__prof', ''),
      $dicts_as_documents := $dicts!json-hal:create_document(xs:anyURI(rest:uri()||'/'||.), <name>{.}</name>)
  return api-problem:or_result(json-hal:create_document_list#10, [rest:uri(), rest:uri(), rest:uri(), rest:uri(), 'dicts', array{$dicts_as_documents}, 1, $pageSize, count($dicts), 1])
};

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}/entries')
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDictDictNameEntries($dict_name as xs:string, $pageSize as xs:integer) {
  let $entries := collection($dict_name)//*:mods,
      $entries_as_documents := subsequence($entries, 1, $pageSize)!_:entryAsDocument(xs:anyURI(rest:uri()||'/'||./@xml:id), .)
  return api-problem:or_result(json-hal:create_document_list#10, [rest:uri(), rest:uri(), rest:uri(), rest:uri(), 'entries', array{$entries_as_documents}, 1, $pageSize, count($entries), 1])
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $entry as element()) {
  json-hal:create_document($_self, (
    <id>{data($entry/@xml:id)}</id>,
    <entry>{serialize($entry)}</entry>))
};

declare
   %rest:GET
   %rest:path('restvle/dicts/{$dict_name}/entries/{$id}')
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string) {
  let $entry := collection($dict_name)//*:mods[@xml:id = $id]
  return api-problem:or_result(_:entryAsDocument#2, [rest:uri(), $entry])
};
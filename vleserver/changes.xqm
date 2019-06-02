(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/changes';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
import module namespace data-changes = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at 'data/changes.xqm';

declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

(:~
 : Get all stored previous versions of a particular entry.
 : @param $dict_name An existing dictionary name
 : @param $id An existing entry id
 : @param $pageSize Number of entries to return per request
 : @param $page The page page to return based on the given pageSize
 : @return A JSON HAL based list of documents. If pageSize is 10 or less the
 :         individual entries are included.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/entries/{$id}/changes')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:produces('application/json')
    (: %rest:produces('application/problem+json') :)   
    (: %rest:produces('application/problem+xml') :)
function _:getDictDictNameEntryIDChanges($dict_name as xs:string, $id as xs:string, $pageSize as xs:integer, $page as xs:integer) {
  let $entries_pres := data-changes:get-pre-and-dt-for-changes-by-id($dict_name, $id),
      $entries_as_documents := subsequence($entries_pres, (($page - 1) * $pageSize) + 1, $pageSize)!_:entryAsDocument(try {xs:anyURI(rest:uri()||'/'||data(./dt))} catch basex:http {xs:anyURI('urn:local')}, ., if ($pageSize <= 10) then data-changes:get-change-by-pre($dict_name, ./p) else ())
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'entries', array{$entries_as_documents}, $pageSize, count($entries_pres), $page], cors:header(()))
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $changes-data as element(_), $entry as element()?) {
  json-hal:create_document($_self, (
    <id>{$changes-data/p/text()}</id>,
    <dt>{$changes-data/dt/text()}</dt>,
    if (exists($entry)) then <lemma>TODO</lemma> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='status'])) then
    <status>{$entry//*:fs[@type='change']/*[@name='status']/*/@value/data/()}</status> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='owner'])) then
    <owner>{$entry//*:fs[@type='change']/*[@name='owner']/*/@value/data/()}</owner> else (),
    if (exists($entry)) then <type>{types:get_data_type($entry)}</type> else (),
    if (exists($entry)) then <entry>{serialize($entry)}</entry> else ()))
};

declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/entries/{$id}/changes/{$change_timestamp}')
function _:getDictDictNameEntryIDChange($dict_name as xs:string, $id as xs:string, $change_timestamp as xs:string) {
  let $entry := data-changes:get-change-by-id-and-dt($dict_name, $id, $change_timestamp),
      $checkIfExists := if (exists($entry)) then true()
       else error(xs:QName('response-codes:_404'),
                           'Not found',
                           'ID '||$id||' timestamp '||$change_timestamp||' not found')
  return api-problem:or_result(_:entryAsDocument#3, [rest:uri(), $entry, $entry/entry/*], cors:header(()))
};
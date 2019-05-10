xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/entries';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}/entries')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDictDictNameEntries($dict_name as xs:string, $pageSize as xs:integer, $page as xs:integer) {
  let $entries_ids := try { data-access:get-all-entries($dict_name)!(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/(@xml:id|@ID)
  };
]``) else ./(@xml:id|@ID)) }
      catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      },
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
    %rest:POST('{$userData}')
    %rest:path('restvle/dicts/{$dict_name}/entries')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
function _:createEntry($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string) {
  let $check_dict_exists := if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-'||$dict_name)) then true()
      else error(xs:QName('response-codes:_404'), 
         $api-problem:codes_to_message(404),
         'Dictionary '||$dict_name||' is not yet created'),
      $check_wanted := if ($wanted-response = "application/vnd.wde.v2+json") then true()
      else error(xs:QName('response-codes:_403'),
         'Only wde.v2 aware clients allowed',
         'Accept has to be application/vnd.wde.v2+json.&#x0a;'||
         'Accept was :'||$wanted-response),
      $check_content_type := if ($content-type = 'application/json') then true()
      (: in this case $data is an element(json) :) 
      else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),
      $check_json := if (exists($userData/json/sid) and
          exists($userData/json/lemma) and
          exists($userData/json/entry)) then true() 
      else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               ``[Need a {
  "sid": "The internal ID. May be empty string.",
  "lemma": "A lemma. May be empty string.",
  "entry": "The entry as XML fragment."
} object.&#x0a;]``||
               'JSON was: '||serialize($userData, map{'method': 'json'})),
      $entry := try {parse-xml-fragment($userData/json/entry/text())/*
        } catch * {
          error(xs:QName('response-codes:_422'),
               'Entry is not paresable as XML',
               'Need some well formed XML. '||
               'XML was: '||$userData/json/entry/text()||'&#x0a;'||
               $err:additional) 
        }
    return api-problem:result(data-access:save_new_entry($entry, $dict_name))
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
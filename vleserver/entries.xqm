xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/entries';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
import module namespace lcks = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at 'data/locks.xqm';
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
      $entries_as_documents := subsequence($entries_ids, (($page - 1) * $pageSize) + 1, $pageSize)!_:entryAsDocument(try {xs:anyURI(rest:uri()||'/'||data(.))} catch basex:http {xs:anyURI('urn:local')}, ., if ($pageSize <= 10) then data-access:get-entry-by-id($dict_name, .) else (), lcks:get_user_locking_entry($dict_name, .))
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'entries', array{$entries_as_documents}, $pageSize, count($entries_ids), $page])
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as attribute(xml:id), $entry as element()?, $isLockedBy as xs:string?) {
  json-hal:create_document($_self, (
    <id>{data($id)}</id>,
    <sid>{data($id)}</sid>,
    if (exists($entry)) then <lemma>TODO</lemma> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='status'])) then
    <status>{$entry//*:fs[@type='change']/*[@name='status']/*/@value/data/()}</status> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='owner'])) then
    <owner>{$entry//*:fs[@type='change']/*[@name='owner']/*/@value/data/()}</owner> else (),
    if (exists($isLockedBy)) then <locked>{}</locked> else (),
    if (exists($entry)) then <type>{types:get_data_type($entry)}</type> else (),
    if (exists($entry)) then <entry>{serialize($entry)}</entry> else ()))
};

declare
    %rest:POST('{$userData}')
    %rest:path('restvle/dicts/{$dict_name}/entries')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
function _:createEntry($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) {
  let $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text()
  return api-problem:or_result(data-access:create_new_entry#5, [$entry, $dict_name, $status, $owner, $userName], 201, ())
};

declare %private function _:checkPassedDataIsValid($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string) as element()+ {
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
        },
      $check_new_node_has_id := if (exists($entry/(@xml:id, @ID))) then true()
        else error(xs:QName('response-codes:_422'),
                  '@xml:id or @ID missing on data node',
                  'Element '||$entry/local-name()||' needs to have either an xml:id attribute or an ID attribute.')   
  return $entry 
};

declare %private function _:getUserNameFromAuthorization($auth_header as xs:string) as xs:string {
  let $name_pw := tokenize(convert:binary-to-string(xs:base64Binary(replace($auth_header, '^Basic ', ''))), ':')
  (: Digest username="UserNameFromAuthorization", .... :)
  return $name_pw[1]
};

declare
    %rest:PUT('{$userData}')
    %rest:path('restvle/dicts/{$dict_name}/entries/{$id}')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
function _:changeEntry($dict_name as xs:string, $id as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) {
  let $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text(),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"') 
  return api-problem:or_result(data-access:change_entry#6, [$entry, $dict_name, $id, $status, $owner, $userName], 200, ())
};

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}/entries/{$id}')
    %rest:query-param("lock", "{$lock}")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string, $lock as xs:string?, $wanted-response as xs:string, $auth_header as xs:string) {
  let $lockDuration := if ($lock castable as xs:integer) then xs:dayTimeDuration('PT'||$lock||'S') 
                       else if ($lock = 'true') then $lcks:maxLockTime
                       else (),
      $checkLockingAllowed := if (not(exists($lockDuration)) or $wanted-response = 'application/vnd.wde.v2+json') then true()
        else error(xs:QName('response-codes:_403'), 
                   $api-problem:codes_to_message(403),
                   'Only wde.v2 clients may request locking'),
      $lockEntry := if (exists($lockDuration)) then lcks:lock_entry($dict_name, _:getUserNameFromAuthorization($auth_header), $id, current-dateTime() + $lockDuration) else (),
      $entry := data-access:get-entry-by-id($dict_name, $id)
  return api-problem:or_result(_:entryAsDocument#4, [rest:uri(), $entry/(@xml:id, @ID), $entry, lcks:get_user_locking_entry($dict_name, $entry/(@xml:id, @ID))])
};

declare
  %rest:DELETE
  %rest:path('restvle/dicts/{$dict_name}/entries/{$id}')
  %rest:header-param('Authorization', '{$auth_header}', "")
function _:deleteDictDictNameEntry($dict_name as xs:string, $id as xs:string, $auth_header as xs:string) {
  api-problem:or_result(data-access:delete_entry#3, [$dict_name, $id, _:getUserNameFromAuthorization($auth_header)])
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
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
import module namespace plugins = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator" at 'plugins/coordinator.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();

(:~
 : A list of all entries for a particular dictionary. TODO: Limit by query.
 :
 : This will be the URI to search for a particular entry by numerous filter
 : an search options.
 : @param $dict_name Name of an existing dictionary
 : @param $pageSize Number of entries to return per request
 : @param $page The page page to return based on the given pageSize
 : @return A JSON HAL based list of entry URIs.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/entries')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:produces('application/json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')   
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntries($dict_name as xs:string, $pageSize as xs:integer, $page as xs:integer) {
  let $nodes_or_dryed := try { data-access:get-all-entries($dict_name) }
      catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      },
      $counts := $nodes_or_dryed!(if (. instance of element(util:dryed)) then xs:integer(./@count) else 1),
      $start-end-pos := for $i at $p in (1, $counts) let $start-pos := sum(($i, (1, $counts)[position() < $p]))
        return <_>
        <s>{$start-pos}</s>
        <e>{if (exists($counts[$p])) then $start-pos + $counts[$p] - 1 else 0}</e>
        <nd>{$nodes_or_dryed[$p]}</nd>
        </_>,
      $from := (($page - 1) * $pageSize) + 1,
      $relevant_nodes_or_dryed := $start-end-pos[xs:integer(./e) >= $from and xs:integer(./s) <= $from+$pageSize],
      $entries_ids := $relevant_nodes_or_dryed/nd/*!(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/(@xml:id|@ID)
  };
]``) else ./(@xml:id|@ID)),
      $from_relevant_nodes := $from - (xs:integer($relevant_nodes_or_dryed[1]/s) - 1),
      $entries_as_documents := subsequence($entries_ids, $from_relevant_nodes, $pageSize)!_:entryAsDocument(try {xs:anyURI(rest:uri()||'/'||data(.))} catch basex:http {xs:anyURI('urn:local')}, ., if ($pageSize <= 10) then data-access:get-entry-by-id($dict_name, .) else (), lcks:get_user_locking_entry($dict_name, .))
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'entries', array{$entries_as_documents}, $pageSize, xs:integer($start-end-pos[last()]/s) - 1, $page])
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as attribute(), $entry as element()?, $isLockedBy as xs:string?) {
  json-hal:create_document($_self, (
    <id>{data($id)}</id>,
    <sid>{data($id)}</sid>,
    if (exists($entry)) then <lemma>TODO</lemma> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='status'])) then
    <status>{$entry//*:fs[@type='change']/*[@name='status']/*/@value/data/()}</status> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='owner'])) then
    <owner>{$entry//*:fs[@type='change']/*[@name='owner']/*/@value/data/()}</owner> else (),
    if (exists($isLockedBy)) then <locked>{$isLockedBy}</locked> else (),
    if (exists($entry)) then <type>{types:get_data_type($entry)}</type> else (),
    if (exists($entry)) then <entry>{serialize($entry)}</entry> else ()))
};

(:~
 : Creates a new dictionary entry.
 : @param $userData JSON describing the new entry.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @param $auth_header Required for getting the user for the changelog
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return 201 Created
 :)
declare
    %rest:POST('{$userData}')
    %rest:path('/restvle/dicts/{$dict_name}/entries')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:arg("userData", '{
  "sid": "The internal ID. May be empty string.",
  "lemma": "A lemma. May be empty string.",
  "entry": "The entry as XML fragment."
}')
function _:createEntry($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) {
  let $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text()
  return api-problem:or_result(_:create_new_entry#5, [$entry, $dict_name, $status, $owner, $userName], 201, ())
};

declare %private function _:create_new_entry($data as element(), $dict as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) {
  let $savedEntry := data-access:create_new_entry($data, $dict, $status, $owner, $changingUser),
      $run_plugins := plugins:after_created($savedEntry, $dict, $savedEntry/(@xml:id, @ID), $status, $owner, $changingUser)
  return _:entryAsDocument(rest:uri()||'/'||$savedEntry/(@ID, @xml:id), $savedEntry/(@ID, @xml:id), $savedEntry, ())          
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


(:~
 : Change a dictionary entry.
 :
 : The entry is saved in the changelog db before it is changed .
 : The authorized user has to won the lock to do this.
 : Otherwise a 422 error is returned.
 : @param $userData JSON describing the changed entry.
 : @param $id The @xml:id or @ID of the entry to be changed.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @param $auth_header Required for getting the user for the changelog.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return The changed entry. Including the changelog entry the server generated.
 :)
declare
    %rest:PUT('{$userData}')
    %rest:path('/restvle/dicts/{$dict_name}/entries/{$id}')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:arg("userData", '{
  "sid": "The internal ID. May be empty string.",
  "lemma": "A lemma. May be empty string.",
  "entry": "The entry as XML fragment."
}')
function _:changeEntry($dict_name as xs:string, $id as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) as item()+ {
  let $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text(),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"') 
  return api-problem:or_result(_:change_entry#6, [$entry, $dict_name, $id, $status, $owner, $userName], 200, ())
};

declare %private function _:change_entry($data as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) {
  let $savedEntry := data-access:change_entry($data, $dict, $id, $status, $owner, $changingUser),
      $run_plugins := plugins:after_updated($savedEntry, $dict, $id, $status, $owner, $changingUser)
  return _:entryAsDocument(rest:uri(), $savedEntry/(@ID, @xml:id), $savedEntry, lcks:get_user_locking_entry($dict, $savedEntry/(@ID, @xml:id)))
};


(:~
 : Get a particular entry from a dictionary.
 :
 : To later save the changed entry it has to be locked using the lock parameter
 : @param $dict_name Name of an existing dictionary.
 : @param $id The @xml:id or @ID of the entry to be changed.
 : @param $lock Whether to lock the entry for later saving it.
 :
 : Can be a time in seconds that tells how long the entry should be
 : locked. Can be true for the maximum amount of time allowed.
 : After at most that timeout the entry needs to be locked again using
 : this function.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @param $auth_header Required for locking the entry otherwise unused.
 : @return A JSON HAL document containing the entry XML and further extracted data.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/entries/{$id}')
    %rest:query-param("lock", "{$lock}")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:produces('application/json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string, $lock as xs:string?, $wanted-response as xs:string+, $auth_header as xs:string) {
  let $lockDuration := if ($lock castable as xs:integer) then
                         let $lockAsDuration := xs:dayTimeDuration('PT'||$lock||'S') 
                         return if ($lockAsDuration > $lcks:maxLockTime) then $lcks:maxLockTime else $lockAsDuration
                       else if ($lock = 'true') then $lcks:maxLockTime
                       else (),
      $checkLockingAllowed := if (not(exists($lockDuration)) or $wanted-response = 'application/vnd.wde.v2+json') then true()
        else error(xs:QName('response-codes:_403'), 
                   $api-problem:codes_to_message(403),
                   'Only wde.v2 clients may request locking'),
      $lockEntry := if (exists($lockDuration)) then lcks:lock_entry($dict_name, _:getUserNameFromAuthorization($auth_header), $id, current-dateTime() + $lockDuration) else (),
      $entry := data-access:get-entry-by-id($dict_name, $id),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $entry/(@xml:id, @ID))
  return api-problem:or_result(_:entryAsDocument#4, [rest:uri(), $entry/(@xml:id, @ID), $entry, $lockedBy])
};

(:~
 : Remove an entry.
 : 
 : The entry is saved in the changelog db before it is removed.
 : The authorized user has to won the lock to do this.
 : Otherwise a 422 error is returned.
 : @param $dict_name Name of an existing dictionary
 : @param $id The @xml:id or @ID of the entry to be deleted.
 : @param $auth_header Required for getting the user for the changelog.
 : @return 204 No Content
 :)
declare
  %rest:DELETE
  %rest:path('/restvle/dicts/{$dict_name}/entries/{$id}')
  %rest:header-param('Authorization', '{$auth_header}', "")
function _:deleteDictDictNameEntry($dict_name as xs:string, $id as xs:string, $auth_header as xs:string) {
  let $userName := _:getUserNameFromAuthorization($auth_header),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"') 
  return api-problem:or_result(_:delete_entry#3, [$dict_name, $id, $userName])
};

declare %private function _:delete_entry($dict as xs:string, $id as xs:string, $changingUser as xs:string) {
  data-access:delete_entry($dict, $id, $changingUser),
  plugins:after_deleted($dict, $id, $changingUser)
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
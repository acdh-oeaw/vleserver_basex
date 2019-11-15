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
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache" at 'data/cache.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at 'data/profile.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
import module namespace lcks = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at 'data/locks.xqm';
import module namespace plugins = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator" at 'plugins/coordinator.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();
declare variable $_:max_results_with_entries := 1000;
declare variable $_:dont_try_to_return_more_than := 200000;

(:~
 : A list of all entries for a particular dictionary. TODO: Limit by query.
 :
 : There seems to be a limit of about 80 ids that can be specified at any one time.
 : This will be the URI to search for a particular entry by numerous filter
 : an search options.
 : Search option are defined as queryTemplates in profiles. They can be used as
 : name=value query parameters.
 : Please note that a client sending Accept application/vnd.wde.v2+json
 : is required to provide credentials. Use application/json or
 : application/hal+json for unrestricted read access.
 : @param $dict_name Name of an existing dictionary
 : @param $pageSize Number of entries to return per request
 : @param $page The page page to return based on the given pageSize
 : @param $id Filter by ids starting with this string
 : @param $ids Return entries matching exactly the ids provided as a comma separated list
 : @param $q XPath or XQuery to exeute as filter (only admins for this dict)
 : @param $sort XPath or XQuery to execute for sorting the filtered results (only admins for this dict)
 : @return A JSON HAL based list of entry URIs.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/entries')
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:header-param('Accept', '{$accept}')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:query-param("id", "{$id}")
    %rest:query-param("ids", "{$ids}")
    %rest:query-param("q", "{$q}")
    %rest:query-param("sort", "{$sort}")
    %rest:query-param("altLemma", "{$altLemma}")
    %test:arg("page", 1)
    %test:arg("pageSize", 10)
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')   
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntries($dict_name as xs:string, $auth_header as xs:string,
                                  $pageSize as xs:integer, $page as xs:integer,
                                  $id as xs:string?, $ids as xs:string?,
                                  $q as xs:string?, $sort as xs:string?,
                                  $altLemma as xs:string?, $accept as xs:string*) {
  let $start-fun := prof:current-ns(),
      $start := $start-fun,
      $check_authenticated_for_q_sort_xquery := if ((exists($q) or
        (exists($sort) and not($sort = ("none", "asc", "desc"))))
        and not($accept = 'application/vnd.wde.v2+json'))
      then error(xs:QName('response-codes:_403'), 
         $api-problem:codes_to_message(403),
         'XQuery for sort or q is only allowed if authenticated')
      else true(),
      $additional_ret_query_parameters := if ($ids) then map {'ids': $ids}
        else if ($id) then map {"id": $id}
        else map {},
      $check_dict_exists := if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-'||$dict_name)) then true()
      else error(xs:QName('response-codes:_404'), 
         $api-problem:codes_to_message(404),
         'Dictionary '||$dict_name||' does not exist'),      
      $id-is-not-empty-or-no-filter :=
        if ($ids instance of xs:string) then
            if ($ids ne '') then true()
            else error(xs:QName('response-codes:_404'),
            $api-problem:codes_to_message(404),
            'ids= does not select anything')
        else if ($id instance of xs:string) then
          if (ends-with($id, '*')) then
            if ($id ne '*') then true()
            else error(xs:QName('response-codes:_400'),
            $api-problem:codes_to_message(400),
            'id=* is no useful filter')
          else
            if ($id ne '') then true()
            else error(xs:QName('response-codes:_404'),
            $api-problem:codes_to_message(404),
            'id= does not select anything'),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $profile := profile:get($dict_name),
      $total_items := 
          if ($ids instance of xs:string) then
            data-access:count-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'))
          else if ($id instance of xs:string) then
            if (ends-with($id, '*')) then
              data-access:count-entries-by-id-starting-with($dict_name, substring-before($id, '*'))
            else
              data-access:count-entries-by-ids($dict_name, $id)
          else if (exists($profile//useCache))
            then cache:count-all-entries($dict_name)
            else data-access:count-all-entries($dict_name),
      $pageSize := max(($pageSize, 1)),
      $page := min((xs:integer(ceiling($total_items div $pageSize)), max((1, $page)))),
      $from := (($page - 1) * $pageSize) + 1,
      $relevant_nodes_or_dryed := if (exists($profile//useCache))
          then _:get-dryed-from-cache($dict_name, $id, $ids, $sort, $altLemma, $from, $pageSize, $total_items)
          else _:get-nodes-or-dryed-direct($dict_name, $id, $ids, $sort, $altLemma, $from, $pageSize, $total_items),
      $relevant_dbs := distinct-values($relevant_nodes_or_dryed/@db_name/data()),
      (: $log := _:write-log('Relevant DBs: '||string-join($relevant_dbs, ', '), 'INFO'), :)
      $relevant_ids := for $nd in $relevant_nodes_or_dryed
        return typeswitch ($nd)
          case  element(util:d) return $nd/(@xml:id|@ID)
          default return $nd/(@xml:id|@ID),
   (: $log := _:write-log('After relevant entries as attributes: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO'),
      $start := prof:current-ns(), :)
      (: $log := _:write-log('Relevant IDs: '||string-join(data($relevant_ids), ', '), 'INFO'), :)
      $locked_entries := lcks:get_user_locking_entries($dict_name, data($relevant_ids)),
      $xml_snippets := if ($pageSize <= $_:max_results_with_entries) 
        then data-access:get-entries-by-ids($dict_name, data($relevant_ids), $relevant_dbs, $_:max_results_with_entries)/*
        else (),
      $xml_snippets_without_sort_key := $xml_snippets transform with {
          delete node ./@*[starts-with(local-name(), $util:vleUtilSortKey)]
        },
   (: $log := _:write-log('Before entries: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO'),
      $start := prof:current-ns(), :)
      $label := if (exists($altLemma)) then '-'||$altLemma else '',
      $entries_as_documents := for $id in $relevant_ids
        (: $relevant_ids is sorted, so the sequence generated here is sorted as well. :)
        return _:entryAsDocument(try {xs:anyURI(rest:uri()||'/'||data($id))} catch basex:http {xs:anyURI('urn:local')}, $id, $id/../@*[local-name() = $util:vleUtilSortKey||$label], $xml_snippets_without_sort_key[(@xml:id, @ID) = data($id)], $locked_entries($id))
 (: , $log := _:write-log('Generate entries: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO') :)
  return api-problem:or_result($start-fun,
    json-hal:create_document_list#7, [
      try {rest:uri()} catch basex:http {xs:anyURI('urn:local')}, 'entries', array{$entries_as_documents}, $pageSize,
      $total_items, $page, $additional_ret_query_parameters
    ], cors:header(())
  )
};

declare function _:get-dryed-from-cache($dict_name as xs:string,
  $id as xs:string?, $ids as xs:string*,
  $sort as xs:string?, $label as xs:string?,
  $from as xs:integer, $num as xs:integer, $total_items_expected as xs:integer) {
    try {
        if ($ids instance of xs:string) then
          cache:get-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'), $from, $num, $sort, $label, $total_items_expected)
        else if ($id instance of xs:string) then
          if (ends-with($id, '*')) then
            cache:get-entries-by-id-starting-with($dict_name, substring-before($id, '*'), $from, $num, $sort, $label, $total_items_expected)
          else
            cache:get-entries-by-ids($dict_name, $id, $from, $num, $sort, $label, $total_items_expected)
        else cache:get-all-entries($dict_name, $from, $num, $sort, $label, $total_items_expected)
    } catch cache:missing {
       _:write-log('cache miss', 'INFO'),
       _:get-nodes-or-dryed-direct($dict_name, $id, $ids, $sort, $label, $from, $num, $total_items_expected)
    }
};

declare %private function _:get-nodes-or-dryed-direct($dict_name as xs:string,
  $id as xs:string?, $ids as xs:string*,
  $sort as xs:string?, $label as xs:string?,
  $from as xs:integer, $num as xs:integer,
  $total_items_expected as xs:integer)
  as element()* {
let (: $start := prof:current-ns(), :)
    $total-items-expected-is-not-more-than := if ($total_items_expected <= $_:dont_try_to_return_more_than) then true()
          else error(xs:QName('response-codes:_413'), 
            $api-problem:codes_to_message(413),
            'You selected '||$total_items_expected||' entries which is more than the server can deliver ('||
            $_:dont_try_to_return_more_than||').'||
            'Use caching if you need to browse more entries.'),
    $label := if (exists($label)) then '-'||$label else '',
    $nodes_or_dryed := try {
        if ($ids instance of xs:string) then
          data-access:get-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'))
        else if ($id instance of xs:string) then
          if (ends-with($id, '*')) then
            data-access:get-entries-by-id-starting-with($dict_name, substring-before($id, '*'))
          else
            data-access:get-entries-by-ids($dict_name, $id)
        else data-access:get-all-entries($dict_name) 
      } catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      },
 (: $log := _:write-log('Got all entries: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO'), :)
    $nodes_or_dryed_sorted := switch($sort)
        case "asc" return for $n in $nodes_or_dryed/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label]
        return $n
        case "desc" return for $n in $nodes_or_dryed/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label] descending
        return $n
        case "none" return $nodes_or_dryed/*
        default return for $n in $nodes_or_dryed/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label]
        return $n
  return subsequence($nodes_or_dryed_sorted, $from, $num)
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as attribute(), $lemma as xs:string, $entry as element()?, $isLockedBy as xs:string?) {
(# db:copynode false #) {
  json-hal:create_document($_self, (
    <id>{data($id)}</id>,
    <sid>{data($id)}</sid>,
    <lemma>{$lemma}</lemma>,
    if (exists($entry//*:fs[@type='change']/*[@name='status'])) then
    <status>{$entry//*:fs[@type='change']/*[@name='status']/*/@value/data/()}</status> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='owner'])) then
    <owner>{$entry//*:fs[@type='change']/*[@name='owner']/*/@value/data/()}</owner> else (),
    if (exists($isLockedBy)) then <locked>{$isLockedBy}</locked> else (),
    if (exists($entry)) then <type>{types:get_data_type($entry)}</type> else (),
    if (exists($entry)) then <entry>{serialize($entry)}</entry> else ()))
}
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
  let $start := prof:current-ns(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text()
  return api-problem:or_result($start, _:create_new_entry#5, [$entry, $dict_name, $status, $owner, $userName], 201, cors:header(()))
};

declare %private function _:create_new_entry($data as element(), $dict as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) {
  let $savedEntry := data-access:create_new_entry($data, $dict, $status, $owner, $changingUser),
      $run_plugins := plugins:after_created($savedEntry('current'), $dict, $savedEntry('current')/(@xml:id, @ID), $savedEntry('db_name'), $status, $owner, $changingUser)
  return _:entryAsDocument(xs:anyURI(rest:uri()||'/'||$savedEntry('current')/(@ID, @xml:id)), $savedEntry('current')/(@ID, @xml:id), 
  profile:extract-sort-values(profile:get($dict), $savedEntry('current'))/@*[local-name() = $util:vleUtilSortKey],
  $savedEntry('current'), ())          
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
      $check_content_type := if (starts-with($content-type,'application/json')) then true()
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
  let $start := prof:current-ns(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $status := $userData/json/status/text(),
      $owner := $userData/json/owner/text(),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"') 
  return api-problem:or_result($start, _:change_entry#6, [$entry, $dict_name, $id, $status, $owner, $userName], 200, cors:header(()))
};

declare %private function _:change_entry($data as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) {
  let $savedEntry as map(xs:string, item()) := data-access:change_entry($data, $dict, $id, $status, $owner, $changingUser),
      $run_plugins := plugins:after_updated($savedEntry('current'), $savedEntry('before'), $dict, $id, $savedEntry('db_name'), $status, $owner, $changingUser)
  return _:entryAsDocument(rest:uri(), $savedEntry('current')/(@ID, @xml:id), 
  profile:extract-sort-values(profile:get($dict), $savedEntry('current'))/@*[local-name() = $util:vleUtilSortKey],
  $savedEntry('current'), lcks:get_user_locking_entry($dict, $savedEntry('current')/(@ID, @xml:id)))
};


(:~
 : Get a particular entry from a dictionary.
 :
 : Please note that a client sending Accept application/vnd.wde.v2+json
 : is required to provide credentials. Use application/json or
 : application/hal+json for unrestricted read access.
 : To later save the changed entry it has to be locked using the lock parameter.
 : This parameter can only be used by clients that accept
 : application/vnd.wde.v2+json thus credentials are required
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
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string, $lock as xs:string?, $wanted-response as xs:string+, $auth_header as xs:string) {
  let $start := prof:current-ns(),
      $lockDuration := if ($lock castable as xs:integer) then
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
  return api-problem:or_result($start, _:entryAsDocument#5, [rest:uri(), $entry/(@xml:id, @ID), 
  profile:extract-sort-values(profile:get($dict_name), $entry)/@*[local-name() = $util:vleUtilSortKey],
  $entry, $lockedBy], cors:header(()))
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
  let $start := prof:current-ns(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"') 
  return api-problem:or_result($start, _:delete_entry#3, [$dict_name, $id, $userName], cors:header(()))
};

declare %private function _:delete_entry($dict as xs:string, $id as xs:string, $changingUser as xs:string) {
  let $ret := data-access:delete_entry($dict, $id, $changingUser)
  return (plugins:after_deleted($dict, $id, $ret('db_name'), $changingUser), $ret('api-response'))
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
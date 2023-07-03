(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/entries';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace hash = "http://basex.org/modules/hash";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace users = 'https://www.oeaw.ac.at/acdh/tools/vle/users' at 'users.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache" at 'data/cache.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at 'data/profile.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
import module namespace lcks = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at 'data/locks.xqm';
import module namespace plugins = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator" at 'plugins/coordinator.xqm';
import module namespace validate = "https://www.oeaw.ac.at/acdh/tools/vle/data/validation" at 'data/validation.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace entries = "https://www.oeaw.ac.at/acdh/tools/vle/entries";

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
 : @param $q A name of a query template stored in the profile (everyone) or
 : an XPath or XQuery to exeute as filter (only admins for this dict)
 : @param $sort One of "asc", "desc" or "none" (everyone) or
 : an XPath or XQuery to execute for sorting the filtered results (only admins for this dict)
 : @param $altLemma A name of an alternative lemma definition to use (specified in profile)
 : @param $lock true or an amount of time in seconds the selected entries should be locked for editing
 : @param $format An XML format the TEI should be transformed to (e. g. html)
 : Only authenticated users.
 : @param $auth_header Used to determine if user is allowed to use any XQuery or XPath for q and sort
 : @param $accept Used to determine if the user was authenticated or is anonymous.
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
    %rest:query-param("lock","{$lock}")
    %rest:query-param("format", "{$format}")
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
                                  $altLemma as xs:string?, $accept as xs:string*,
                                  $lock as xs:string?,
                                  $format as xs:string?) {
  let $start-fun := prof:current-ns(),
      $start := $start-fun,
      $check_dict_exists := if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-'||$dict_name)) then true()
      else error(xs:QName('response-codes:_404'), 
         $api-problem:codes_to_message(404),
         'Dictionary '||$dict_name||' does not exist'),
      $profile := profile:get($dict_name),
      $query-templates := profile:get-query-templates($profile),
      $query-template-name := if (empty($q)) then () else replace($q, '^([^=]+)=(.*)$', '$1'),
      $query-value := if (empty($q)) then () else replace($q, '^([^=]+)=(.*)$', '$2'),
      $check_authenticated_for_q_sort_xquery := if ((
        (exists($q) and not($query-template-name = map:keys($query-templates))) or
        (exists($sort) and not($sort = ("none", "asc", "desc"))))
        and not($accept = 'application/vnd.wde.v2+json'))
      then error(xs:QName('response-codes:_403'), 
         $api-problem:codes_to_message(403),
         'XQuery for sort or q is only allowed if authenticated')
      else true(),
      $lockDuration := if ($lock castable as xs:integer) then
                         let $lockAsDuration := xs:dayTimeDuration('PT'||$lock||'S') 
                         return if ($lockAsDuration > $lcks:maxLockTime) then $lcks:maxLockTime else $lockAsDuration
                       else if ($lock = 'true') then $lcks:maxLockTime
                       else (),
      $check_authenticated_for_lock := if (exists($lockDuration) and not($accept = 'application/vnd.wde.v2+json'))
      then error(xs:QName('response-codes:_403'), 
         $api-problem:codes_to_message(403),
         'Locking entries is only allowed if authenticated')
      else true(),
      $q_is_a_query_template := if (exists($q) and not($query-template-name = map:keys($query-templates))) then
        error(xs:QName('entries:not_implemented'), 'Not yet implemented')
      else true(),
      $additional_ret_query_parameters := map:merge((
        if ($q) then map {'q': $q}
        else if ($ids) then map {'ids': $ids}
        else if ($id) then map {"id": $id}
        else map {},
        if ($format) then map{'format': $format}
        else map {},
        if ($sort) then map{'sort': $sort}
        else map {},
        if ($altLemma) then map{'altLemma': $altLemma}
        else map {}
        )),
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
            'id= does not select anything')
         else true(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $total_items := 
      api-problem:trace-info('@entries@getDictDictNameEntries@total_items',
          prof:track(
          if ($q instance of xs:string) then
            data-access:count-entries-selected-by-query($dict_name, $profile, $query-templates($query-template-name), $query-value)
          else if ($ids instance of xs:string) then
           if (exists($profile//useCache))
            then cache:count-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'))
            else api-problem:trace-info('@access@count-entries-by-ids',
              prof:track(data-access:count-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'))))
          else if ($id instance of xs:string) then
            if (ends-with($id, '*')) then
            if (exists($profile//useCache))
              then cache:count-entries-by-id-starting-with($dict_name, substring-before($id, '*'))
              else api-problem:trace-info('@access@count-entries-by-id-starting-with',
              prof:track(data-access:count-entries-by-id-starting-with($dict_name, substring-before($id, '*'))))
            else if (exists($profile//useCache))
              then cache:count-entries-by-ids($dict_name, $id)
              else api-problem:trace-info('@access@count-entries-by-ids',
              prof:track(data-access:count-entries-by-ids($dict_name, $id)))
          else if (exists($profile//useCache))
            then cache:count-all-entries($dict_name)
            else data-access:count-all-entries($dict_name)
          )
        )
          ,
      $some_items_found := if ($total_items?value > 0) then true()
        else error(xs:QName('response-codes:_404'),
            $api-problem:codes_to_message(404),
            'Your query did not yield any items.'),
      $pageSize := max(($pageSize, 1)),
      $page := min((xs:integer(ceiling($total_items?value div $pageSize)), max((1, $page)))),
      $from := (($page - 1) * $pageSize) + 1,
      $query-template := if (empty($query-template-name)) then () else $query-templates($query-template-name),
      $relevant_nodes_or_dryed := api-problem:trace-info('@entries@getDictDictNameEntries@relevant_nodes_or_dryed',
        prof:track(
          if (exists($profile//useCache))
          then _:get-dryed-from-cache($dict_name, $profile, $query-template, $query-value, $id, $ids, $sort, $altLemma, $from, $pageSize, $total_items?value)
          else _:get-nodes-or-dryed-direct($dict_name, $profile, $query-template, $query-value, $id, $ids, $sort, $altLemma, $from, $pageSize, $total_items?value))),
      $relevant_dbs := distinct-values($relevant_nodes_or_dryed?value/@db_name/data()),
      (: $log := _:write-log('Relevant DBs: '||string-join($relevant_dbs, ', '), 'INFO'), :)
      $relevant_ids := for $nd in $relevant_nodes_or_dryed?value
        return typeswitch ($nd)
          case  element(util:d) return $nd/(@xml:id|@ID)
          default return $nd/(@xml:id|@ID),
   (: $log := _:write-log('After relevant entries as attributes: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO'),
      $start := prof:current-ns(), :)
      (: $log := _:write-log('Relevant IDs: '||string-join(data($relevant_ids), ', '), 'INFO'), :)
      $lockEntry := prof:track(
        if (exists($lockDuration)) then lcks:lock_entry($dict_name, _:getUserNameFromAuthorization($auth_header), data($relevant_ids), current-dateTime() + $lockDuration) else ()),
      $locked_entries := lcks:get_user_locking_entries($dict_name, data($relevant_ids)),
      $xml_snippets_without_sort_key :=       
        if ($pageSize <= $_:max_results_with_entries) 
        then _:to-map-by-id(data-access:get-entries-by-ids($dict_name, data($relevant_ids), $relevant_dbs, $_:max_results_with_entries))
        else map{"value": map{}},
      $label := if (exists($altLemma)) then '-'||$altLemma else '',
      $entries_as_documents := api-problem:trace-info('@entries@getDictDictNameEntries@entries_as_documents',
        prof:track(
        let $base_uri := (try {util:uri()} catch basex:http {'urn:local'})||'/'
        return
        for $id in $relevant_ids
        (: $relevant_ids is sorted, so the sequence generated here is sorted as well. :)
        let $lemma := $id/../@*[local-name() = $util:vleUtilSortKey||$label],
            $entry := $xml_snippets_without_sort_key?value($id),
            $ret := _:entryAsDocument(xs:anyURI($base_uri||data($id)), $id, $lemma, $entry, $locked_entries($id), $profile, $format)
        return map{'value': $ret?value,
                   'timings': array:join(($ret?timings))} (:array{$lemma?timings?*} ,  :)
        ))
  return
  (: serialize($entries_as_documents, map {'method': 'basex'}) :)
  api-problem:or_result($start-fun,
    json-hal:create_document_list#8, [
      try {util:uri()} catch basex:http {xs:anyURI('urn:local')}, 'entries', array{$entries_as_documents?value}, $pageSize,
      $total_items?value, $page, $additional_ret_query_parameters,
      array{$total_items?timings?*, $relevant_nodes_or_dryed?timings?*, map{'@entries@getDictDictNameEntries@lockEntry': $lockEntry?time},
            $xml_snippets_without_sort_key?timings?*, $entries_as_documents?timings?*}
    ], cors:header(()) 
  )
};

declare function _:to-map-by-id($in as map(*)) as map(*)? {
  (: admin:write-log(serialize($in?value[not(. instance of node())], map {'method': 'basex'}), 'INFO'), :)
  let $found-in-parts as node()* := $in?value
  return map{
    'value': 
      if (exists($found-in-parts)) then map:merge((map{'db_names': $found-in-parts/@db_name}, $found-in-parts/*!map{data(./(@xml:id, @ID)): . transform with {
          delete node ./@*[starts-with(local-name(), $util:vleUtilSortKey)]
        }}))
      else (),
    'timings': $in?timings
  }
};

declare function _:get-dryed-from-cache($dict_name as xs:string,
  $profile as document-node(), $query-template as xs:string?, $query-value as xs:string?,
  $id as xs:string?, $ids as xs:string*,
  $sort as xs:string?, $label as xs:string?,
  $from as xs:integer, $num as xs:integer, $total_items_expected as xs:integer) as map(*) {
api-problem:trace-info('@entries@get-dryed-from-cache',
            prof:track(
    try {
        if ($query-template instance of xs:string) then
          error(xs:QName('cache:missing'), 'Not implemented yet')
        else if ($ids instance of xs:string) then
          cache:get-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'), $from, $num, $sort, $label, $total_items_expected)
        else if ($id instance of xs:string) then
          if (ends-with($id, '*')) then
            cache:get-entries-by-id-starting-with($dict_name, substring-before($id, '*'), $from, $num, $sort, $label, $total_items_expected)
          else
            cache:get-entries-by-ids($dict_name, $id, $from, $num, $sort, $label, $total_items_expected)
        else cache:get-all-entries($dict_name, $from, $num, $sort, $label, $total_items_expected)
    } catch cache:missing {
       _:write-log('cache miss '||$err:description, 'INFO'),
       _:get-nodes-or-dryed-direct($dict_name, $profile, $query-template, $query-value, $id, $ids, $sort, $label, $from, $num, $total_items_expected)
    }))
};

declare %private function _:get-nodes-or-dryed-direct($dict_name as xs:string,
  $profile as document-node(), $query-template as xs:string?, $query-value as xs:string?,
  $id as xs:string?, $ids as xs:string*,
  $sort as xs:string?, $label as xs:string?,
  $from as xs:integer, $num as xs:integer,
  $total_items_expected as xs:integer)
  as map(*) {
api-problem:trace-info('@entries@get-nodes-or-dryed-direct',
            prof:track(
let (: $start := prof:current-ns(), :)
    $total-items-expected-is-not-more-than := if ($total_items_expected <= $_:dont_try_to_return_more_than) then true()
          else error(xs:QName('response-codes:_413'), 
            $api-problem:codes_to_message(413),
            'You selected '||$total_items_expected||' entries which is more than the server can deliver ('||
            $_:dont_try_to_return_more_than||').'||
            ' Use caching if you need to browse more entries.'),
    $label := if (exists($label)) then '-'||$label else '',
    $nodes_or_dryed := 
      api-problem:trace-info('@entries@get-nodes-or-dryed-direct@nodes_or_dryed',
      prof:track(
      try {
        if ($query-template instance of xs:string) then
          (data-access:get-entries-selected-by-query($dict_name, $profile, $query-template, $query-value)
          (: , admin:write-log('get-entries-selected-by-query', 'INFO') :)
          )
        else if ($ids instance of xs:string) then
          (data-access:get-entries-by-ids($dict_name, tokenize($ids, '\s*,\s*'))
          (: , admin:write-log('get-entries-by-ids', 'INFO') :)
          )
        else if ($id instance of xs:string) then
          if (ends-with($id, '*')) then
            (data-access:get-entries-by-id-starting-with($dict_name, substring-before($id, '*'))
             (: , admin:write-log('get-entries-by-id-starting-with', 'INFO') :)
            )
          else
            (data-access:get-entries-by-ids($dict_name, $id)
             (:, admin:write-log('get-entries-by-ids', 'INFO') :)
            )
        else (data-access:get-all-entries($dict_name)
            (: , admin:write-log('get-all-entries', 'INFO') :)
             ) 
      } catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      })),
 (: $log := _:write-log('Got all entries: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO'), :)
    (: $_ := admin:write-log(serialize($nodes_or_dryed?value, map {'method':'basex'}), 'INFO'), :)
    $nodes_or_dryed_sorted := switch($sort)
        case "asc" return for $n in $nodes_or_dryed?value/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label]
        return $n
        case "desc" return for $n in $nodes_or_dryed?value/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label] descending
        return $n
        case "none" return $nodes_or_dryed?value/*
        default return for $n in $nodes_or_dryed?value/*
        order by $n/@*[local-name() = $util:vleUtilSortKey||$label]
        return $n
  return subsequence($nodes_or_dryed_sorted, $from, $num)))
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as xs:string, $lemma as xs:string, $entry as element()?) {
  _:entryAsDocument($_self, $id, $lemma, $entry, (), (), ())
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as xs:string, $lemma as xs:string, $entry as element()?, $isLockedBy as xs:string?, $profile as document-node()?, $format as xs:string?) {
  _:entryAsDocument($_self, $id, $lemma, $entry, $isLockedBy, (), (), ())
};

declare
  %private
function _:entryAsDocument($_self as xs:anyURI, $id as xs:string, $lemma as xs:string, $entry as element()?, $isLockedBy as xs:string?, $profile as document-node()?, $format as xs:string?, $caller_timings as array(*)?) {
api-problem:trace-info('@entries@entryAsDocument',
            prof:track(
(# db:copynode false #) {
  json-hal:create_document($_self, (
    <id>{$id}</id>,
    <sid>{$id}</sid>,
    <lemma>{$lemma}</lemma>,
    if (exists($entry//*:fs[@type='change']/*[@name='status'])) then
    <status>{$entry//*:fs[@type='change']/*[@name='status']/*/@value/data()}</status> else (),
    if (exists($entry//*:fs[@type='change']/*[@name='owner'])) then
    <owner>{$entry//*:fs[@type='change']/*[@name='owner']/*/@value/data()}</owner> else (),
    if (exists($isLockedBy)) then <locked>{$isLockedBy}</locked> else (),
    if (exists($entry)) then
      let $entry_as_txt := if (exists($format)) then profile:transform-to-format($profile, $entry, $format) else serialize($entry)
      return (
      <type>{types:get_data_type($entry)}</type>,
      <entry>{$entry_as_txt}</entry>
      , <storedEntryMd5>{string(xs:hexBinary(hash:md5($entry_as_txt)))}</storedEntryMd5> 
      )
    else ()))
}), $caller_timings)
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
} or
entries: [{
  "sid": "The internal ID. May be empty string.",
  "lemma": "A lemma. May be empty string.",
  "entry": "The entry as XML fragment."
}]')
function _:createEntry($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) {
  let $start := prof:current-ns(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $check_content_type := if (starts-with($content-type,'application/json')) then true()
      (: in this case $data is an element(json) :) 
      else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),
      $entries := for $entry in $userData/json/entries/_
      let $entryData := <_><json>{($userData/json/@*, $entry/*)}</json></_>
      return _:checkPassedDataIsValid($dict_name, $entryData, $content-type, $wanted-response)
  return if (exists($entries)) then
  let $create_new_data as map(xs:string, map(xs:string, item()?)) := map:merge(for $entry in $entries
    return map {$entry?id: map:merge((map { "as_document": _:entryAsDocument(try {xs:anyURI(util:uri()||'/'||$entry?id)} catch basex:http {xs:anyURI('urn:local')}, $entry?id,
          profile:extract-sort-values(profile:get($dict_name), $entry?entry)/@*[local-name() = $util:vleUtilSortKey], $entry?entry)}, $entry))}),
      (: $log := _:write-log(serialize($create_new_data, map {'method': 'basex'}), 'INFO'), :)
      $create_new := _:create_new_entries($create_new_data, $dict_name, $userName)
  return api-problem:or_result($start,
    json-hal:create_document_list#7, [
      try {util:uri()} catch basex:http {xs:anyURI('urn:local')}, 'entries', array{$create_new_data?*?as_document?value}, map:size($create_new_data),
      map:size($create_new_data), 1, map {}
    ], cors:header(())
  )
  else
  let $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response),
      $entry_data as map(xs:string, map(xs:string, item()?)) := map {$entry?id: $entry}
    (: , $log := _:write-log(serialize($entry_data, map {'method': 'basex'}), 'INFO') :)
  return api-problem:or_result($start, _:create_new_entries#3, [$entry_data, $dict_name, $userName], 201, cors:header(()))
};

(: $data: map(xs:string, map(xs:string, item())) 
    map {'id': map {entry: <xml></xml>
                    status: ()|xs:string
                    owner: ()|xs:string}
         'id': ...}
:)

declare %private function _:create_new_entries($data as map(xs:string, map(xs:string, item()?)), $dict as xs:string, $changingUser as xs:string) {
  let $savedEntries := data-access:create_new_entries($data, $dict, $changingUser),
      $run_plugins := plugins:after_created($savedEntries, $dict, $changingUser)
    (: , $log := _:write-log('entries:create_new_entries() $savedEntries := '||serialize($savedEntries, map{'method': 'basex'}), "DEBUG") :)
  return map:for-each($savedEntries('current'), function($id, $savedEntry) {_:entryAsDocument(xs:anyURI(util:uri()||'/'||$id), $id, 
  profile:extract-sort-values(profile:get($dict), $savedEntry?entry)/@*[local-name() = $util:vleUtilSortKey],
  $savedEntry?entry)})     
};

declare %private function _:checkPassedDataIsValid($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string) as map(xs:string, item()?) {
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
      $entry := try {parse-xml-fragment($userData/json/entry/text())
        } catch * {
          error(xs:QName('response-codes:_422'),
               'Entry is not parseable as XML'||$err:additional,
               'Need some well formed XML. '||
               'XML was: '||$userData/json/entry/text()||'&#x0a;'||
               $err:additional) 
        },
       $testfortextnodeonly := if ($entry/child::node() instance of text()) then error(xs:QName('response-codes:_422'),'Error during parsing','Data consists only of text - no markup') else(),
       $check_new_node_has_id := if (exists($entry/*/(@ID, @xml:id))) then true()
         else error(xs:QName('response-codes:_422'),
                  '@xml:id or @ID missing on data node'||serialize($entry),
                  'Element '||$entry/local-name()||' needs to have either an xml:id attribute or an ID attribute.'),
       $check_id_matches_xml_id_if_exists := if (not(exists($userData/json/id)) or $entry/*/(@ID, @xml:id)/data() eq $userData/json/id) then true()
         else error(xs:QName('response-codes:_422'),
                  '@xml:id or @ID '||$entry/*/(@ID, @xml:id)/data()||'does not match JSON id '||xs:string($userData/json/id),
                  'Element '||$entry/local-name()||' needs to have the same xml:id attribute or an ID attribute value as the JSON id'||xs:string($userData/json/id)||' provided.'),
       $entry_type := types:get_data_type_of_document($entry),
       $validation := if ($entry_type = 'entry') then validate:xml(profile:get($dict_name), $entry)  
  return map{
    'id': xs:string($entry/*/(@xml:id, @ID)),
    'sid': xs:string($userData/json/sid),
    'lemma': xs:string($userData/json/lemma),
    'entry': $entry/*,
    'status': xs:string($userData/json/status),
    'owner': xs:string($userData/json/owner),
    'storedEntryMd5': xs:string($userData/json/storedEntryMd5)
  }
};

declare %private function _:getUserNameFromAuthorization($auth_header as xs:string) as xs:string {
  let $name_pw := tokenize(util:basic-auth-decode($auth_header), ':')
  (: Digest username="UserNameFromAuthorization", .... :)
  return $name_pw[1]
};

(:~
 : Change entries in a dictionary.
 :
 : The entries are saved in the changelog db before they is changed .
 : The authorized user has to own the lock for all the entries to do this.
 : Otherwise a 422 error is returned.
 : @param $userData JSON describing the changed entry.
 : @param $id The @xml:id or @ID of the entry to be changed.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @param $auth_header Required for getting the user for the changelog.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 409 if any of the optionally sent checksums do not match
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return The changed entry. Including the changelog entry the server generated.
 :)
declare
    %rest:method('PATCH', '{$userData}')
    %rest:path('/restvle/dicts/{$dict_name}/entries')
    %rest:query-param("as-user", "{$as-user}")
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:arg("userData", '{entries: [{
  "id": "The xml:id of the entry to change",
  "sid": "The internal ID. May be empty string.",
  "lemma": "A lemma. May be empty string.",
  "entry": "The entry as XML fragment.",
  "storedEntryMd5": "Optional: the last known checksum for the entry in the DB.",
  "owner": "Optional: set (or clear) the owner of an entry. TODO: enforce only write own",
  "status": "Optional: set (or clear) a status string. &apos;released&apos; was used with some special meaning in the past"
}]}')
function _:changeEntries($dict_name as xs:string, $userData, $as-user as xs:string?, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) as item()+ {
  let $start := prof:current-ns(),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $check_user_is_allowed_to_impersonate := if (not(exists($as-user)) or users:is-su($dict_name, $userName)) then true()
      else error(xs:QName('response-codes:_403'),
         'You are not allowed to use the as-user query parameter',
         'Only super users may imperosnate other users'),      
      $check_content_type := if (starts-with($content-type,'application/json')) then true()
      (: in this case $data is an element(json) :) 
      else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),
      $check_if_entries_array_exists := if (exists($userData/json/entries)) then true()
      else error(xs:QName('response-codes:_422'),
         'No entries to change found.',
         'Entries need to be sent as {"entries": [{"id": ...}, {"id": ...}]}. Was: '||serialize($userData/json, map{'method': 'json'})),  
      $ids := $userData/json/entries/_/id!xs:string(.),
      $check_there_are_ids := if (exists($ids)) then true()
      else error(xs:QName('response-codes:_422'), 
         'No IDs specified in request.',
         'Entries need to be sent as {"entries": [{"id": ...}, {"id": ...}]}. Was: '||serialize($userData/json, map{'method': 'json'})),
      $entries := prof:track(for $entry in $userData/json/entries/_
      let $entryData := <_><json>{($userData/json/@*, $entry/*)}</json></_>
      return _:checkPassedDataIsValid($dict_name, $entryData, $content-type, $wanted-response)),    
      $lockedBy := prof:track(lcks:get_user_locking_entries($dict_name, $userData/json/entries/_/id))
     (: return $lockedBy :)
     ,  $checkLockedByCurrentUser := if ($userName = $lockedBy?value?*) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for all the entries',
                   'Entries are currently locked by "'||string-join($lockedBy?value?*, '", "')||'"'),
      (: $changes_data as map(xs:string, map(xs:string, item()?)) := :)
      $changes_data := api-problem:trace-info('@entries@changeEntries@changes_data',
              prof:track(map:merge(for $entry in $entries?value
        return map {$entry?id: map:merge((map {"as_document": _:entryAsDocument(try {xs:anyURI(util:uri()||'/'||$entry?id)} catch basex:http {xs:anyURI('urn:local')}, $entry?id,
          profile:extract-sort-values(profile:get($dict_name), $entry?entry)/@*[local-name() = $util:vleUtilSortKey], $entry?entry), "storedEntryMd5": $entry?storedEntryMd5}, $entry))}))),
      (: $log := _:write-log("entries:changeEntries$change_data "||serialize($changes_data, map {'method': 'basex'}), 'INFO'), :)
      $entries_as_documents := 
      api-problem:trace-info('@entries@changeEntries@entries_as_documents',
              prof:track(
                _:change_entries($changes_data?value, $dict_name, $userName)
              ))
  return api-problem:or_result($start,
    json-hal:create_document_list#8, [
      try {util:uri()} catch basex:http {xs:anyURI('urn:local')}, 'entries', array{$entries_as_documents?value}, count($entries_as_documents?value),
      count($entries_as_documents?value), 1, map {}, array{(map {'@entries@changeEntries:check_entries': $entries?time, '@entries@changeEntries:check_locking': $lockedBy?time}, $changes_data?timings?*, $entries_as_documents?timings?*)}
    ], cors:header(())
  )
};

declare %private function _:change_entries($data as map(xs:string, map(xs:string, item()?)), $dict as xs:string, $changingUser as xs:string) {
  _:change_entries($data, $dict, $changingUser, ())
};

declare %private function _:change_entries($data as map(xs:string, map(xs:string, item()?)), $dict as xs:string, $changingUser as xs:string, $caller_timings as array(*)?) {
  let $savedEntry := data-access:change_entries($data, $dict, $changingUser),
      (: $log := _:write-log(serialize($savedEntry?value, map{'method': 'basex'}), 'INFO'), :)
      $run_plugins := plugins:after_updated($savedEntry?value, $dict, $changingUser)
  return api-problem:trace-info('@entries@change_entries@create_documents',
      prof:track(map:for-each($savedEntry?value('current'), function($id, $data) {_:entryAsDocument(xs:anyURI(util:uri()||'/'||$id), $id, 
  profile:extract-sort-values(profile:get($dict), $data?entry)/@*[local-name() = $util:vleUtilSortKey],
  $data?entry)})), array:join(($caller_timings, $savedEntry?timings, $run_plugins?timings)))
}; 

(:~
 : Change a dictionary entry.
 :
 : The entry is saved in the changelog db before it is changed .
 : The authorized user has to own the lock to do this.
 : Otherwise a 422 error is returned.
 : @param $userData JSON describing the changed entry.
 : @param $id The @xml:id or @ID of the entry to be changed.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @param $auth_header Required for getting the user for the changelog.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 409 if any of the optionally sent checksums do not match
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
  "entry": "The entry as XML fragment.",
  "storedEntryMd5": "Optional: the last known checksum for the entry in the DB.",
  "owner": "Optional: set (or clear) the owner of an entry. TODO: enforce only write own",
  "status": "Optional: set (or clear) a status string. &apos;released&apos; was used with some special meaning in the past"
}')
function _:changeEntry($dict_name as xs:string, $id as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) as item()+ {
  let $start := prof:current-ns(),
      $userName := api-problem:trace-info('@entries@changeEntry@getUserNameFromAuthorization',
      prof:track(_:getUserNameFromAuthorization($auth_header))),
      $entry := api-problem:trace-info('@entries@changeEntry@checkPassedDataIsValid',
      prof:track(_:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response))),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $id),
      $checkLockedByCurrentUser := if ($userName?value = $lockedBy) then true()
        else error(xs:QName('response-codes:_422'),
                   'You don&apos;t own the lock for this entry',
                   'Entry is currently locked by "'||$lockedBy||'"'),
      $change_data as map(xs:string, map(xs:string, item()?)) :=
      map { $entry?value?id: $entry?value}
  return api-problem:or_result($start, _:change_entries#4, [$change_data, $dict_name, $userName?value, array:join(($userName?timings, $entry?timings))], 200, cors:header(()))
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
    %rest:query-param("format", "{$format}")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntry($dict_name as xs:string, $id as xs:string, $lock as xs:string?, $format as xs:string?, $wanted-response as xs:string+, $auth_header as xs:string) {
  try {
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
      $profile := profile:get($dict_name),
      $relevant_nodes_or_dryed := api-problem:trace-info('@entries@getDictDictNameEntry@relevant_nodes_or_dryed',
        prof:track(
          if (exists($profile//useCache))
          then _:get-dryed-from-cache($dict_name, $profile, (), (), $id, (), (), (), 1, 1, 1)
          else _:get-nodes-or-dryed-direct($dict_name, $profile, (), (), $id, (), (), (), 1, 1, 1))),
      $lockedBy := lcks:get_user_locking_entry($dict_name, $relevant_nodes_or_dryed?value/(@xml:id, @ID)),
      $entry := data-access:get-entries-by-ids($dict_name, data($relevant_nodes_or_dryed?value/(@xml:id, @ID)), $relevant_nodes_or_dryed?value/@db_name/data(), 1)
  return api-problem:or_result($start, _:entryAsDocument#8, [util:uri(), $entry?value/*/(@xml:id, @ID), 
  profile:extract-sort-values($profile, $entry?value/*)/@*[local-name() = $util:vleUtilSortKey],
  $entry?value/* transform with {delete node ./@*[starts-with(local-name(), $util:vleUtilSortKey)]}, $lockedBy, $profile, $format,
  array:join(($relevant_nodes_or_dryed?timings, $entry?timings))], cors:header(()))
  } catch lcks:held {
    error(xs:QName('response-codes:_422'),
                   'You cannot lock entry '||$id,
                   'Entry is currently locked by "'||$err:value('user')||'"')
  }
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
  let $ret := data-access:delete_entry($dict, $id, $changingUser),
      $_  := plugins:after_deleted($dict, $id, $ret('db_name'), $changingUser)
  return ($_('no_value'), $ret('api-response'))
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};

declare %private function _:write-log($message as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, "TRACE") else ()
};
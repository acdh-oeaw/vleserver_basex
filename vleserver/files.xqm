(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/files';

import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace users = 'https://www.oeaw.ac.at/acdh/tools/vle/users' at 'users.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at 'data/profile.xqm';
import module namespace lcks = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at 'data/locks.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace plugins = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator" at 'plugins/coordinator.xqm';
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';

declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

(:~
 : A list of all files for a particular dictionary.
 :
 : @param $dict_name Name of an existing dictionary
 : @param $pageSize Number of entries to return per request
 : @param $page The page page to return based on the given pageSize
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}/files')
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:header-param('Accept', '{$accept}')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:query-param("lock","{$lock}")
    %test:arg("page", 1)
    %test:arg("pageSize", 10)
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')   
    %rest:produces('application/problem+xml')
function _:getDictDictNameFiles($dict_name as xs:string, $auth_header as xs:string,
                                  $pageSize as xs:integer, $page as xs:integer,
                                  $accept as xs:string*,
                                  $lock as xs:string?) {
  let $start-fun := prof:current-ns(),
      $start := $start-fun,
      $check_dict_exists := if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-'||$dict_name)) then true()
      else error(xs:QName('response-codes:_404'), 
         $api-problem:codes_to_message(404),
         'Dictionary '||$dict_name||' does not exist'),
      $profile := profile:get($dict_name),
      $db-names := ($dict_name, profile:get-list-of-data-dbs($profile)),
      $locked_entries := lcks:get_user_locking_entries($dict_name),
      $files_as_documents := for $db-name in $db-names
        (: $relevant_ids is sorted, so the sequence generated here is sorted as well. :)
        return _:fileAsDocument(try {xs:anyURI(rest:uri()||'/'||data($db-name)||'.xml')} catch basex:http {xs:anyURI('urn:local')}, $db-name, $locked_entries($db-name), ()),
      $total_items := count($files_as_documents)
 (: , $log := _:write-log('Generate entries: '||((prof:current-ns() - $start) idiv 10000) div 100||' ms', 'INFO') :)
  return api-problem:or_result($start-fun,
    json-hal:create_document_list#7, [
      try {rest:uri()} catch basex:http {xs:anyURI('urn:local')}, 'files', array{$files_as_documents}, $pageSize,
      $total_items, $page, map {}
    ], cors:header(())
  )
};

declare
  %private
function _:fileAsDocument($_self as xs:anyURI, $db-name as xs:string, $isLockedBy as xs:string?, $wanted-response as xs:string*) {
(# db:copynode false #) {
  json-hal:create_document($_self, (
    <fileName>{$db-name}.xml</fileName>,
    if (exists($isLockedBy)) then <locked>{$isLockedBy}</locked> else (),
    if (exists($wanted-response)) then <wantedResponse>{string-join($wanted-response, ', ')}</wantedResponse> else ()))
}
};

(:~
 : Creates a new dictionary entry.
 : @param $userData JSON describing the new file.
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
    %rest:path('/restvle/dicts/{$dict_name}/files')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:consumes('application/json')
    %test:arg("userData", '{
  "fileName": "File name.",
  "xmlData": "File content.",
}')
function _:createFile($dict_name as xs:string, $userData, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) {
  let $start := prof:current-ns(),
      $is_super_user := users:check_super_user($dict_name),
      $userName := _:getUserNameFromAuthorization($auth_header),
      $check_content_type := if (starts-with($content-type,'application/json')) then true()
      (: in this case $data is an element(json) :) 
      else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),
      $xmlData := $userData/json/xmlData,
      $entry := _:checkPassedDataIsValid($dict_name, $userData, $content-type, $wanted-response)
    (: , $log := _:write-log(serialize($entry_data, map {'method': 'basex'}), 'INFO') :)
  return api-problem:or_result($start, _:create_new_file#3, [$entry, $dict_name, $userName], 201, cors:header(()))
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
      $check_json := if (exists($userData/json/fileName) and
          exists($userData/json/xmlData)) then true() 
      else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               ``[Need a {
  "fileName": "File name.",
  "xmlData": "File content.",
} object.&#x0a;]``||
               'JSON was: '||serialize($userData, map{'method': 'json'})),
      $entry := try {parse-xml($userData/json/xmlData/text())
        } catch * {
          error(xs:QName('response-codes:_422'),
               'Entry is not parseable as XML'||$err:additional,
               'Need some well formed XML. '||
               'XML was: '||$userData/json/entry/text()||'&#x0a;'||
               $err:additional) 
        },
       $testfortextnodeonly := if ($entry/child::node() instance of text()) then error(xs:QName('response-codes:_422'),'Error during parsing','Data consists only of text - no markup') else()
  return map{
    'fileName': xs:string($userData/json/fileName),
    'xmlData': $entry
  }
};

declare %private function _:create_new_file($data as map(xs:string, item()?), $dict as xs:string, $changingUser as xs:string) {
  let $savedEntries := data-access:create_new_file($data, $dict, $changingUser),
      $run_plugins := plugins:after_created($savedEntries, $dict, $changingUser)
    (: , $log := _:write-log('files:create_new_file() $savedEntries := '||serialize($savedEntries, map{'method': 'basex'}), "DEBUG") :)
  return _:fileAsDocument(xs:anyURI(rest:uri()||'/'||$data('fileName')), replace($data('fileName'), '.xml$', ''), 'true', ('application/xml'))     
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
 : @param $db-name The @xml:id or @ID of the entry to be changed.
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
    %rest:path('/restvle/dicts/{$dict_name}/files/{$db-name}.xml')
    %rest:query-param("lock", "{$lock}")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', "")
    %rest:produces('application/xml')
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
function _:getDictDictNameEntry($dict_name as xs:string, $db-name as xs:string, $lock as xs:string?, $wanted-response as xs:string+, $auth_header as xs:string) {
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
      $lockEntry := if (exists($lockDuration)) then
        for $id in data-access:get-all-entries($dict_name)
        return lcks:lock_entry($dict_name, _:getUserNameFromAuthorization($auth_header), $id, current-dateTime() + $lockDuration) else (),
      $lockedBy := lcks:get_user_locking_entries($dict_name)
  return if ($wanted-response!replace(., ';.*', '') = ('application/xml'))
  then api-problem:or_result($start, _:fileAsXML#2, [$dict_name, $db-name], map:merge((map{'Content-Type': 'application/xml'}, cors:header(()))))
  else api-problem:or_result($start, _:fileAsDocument#4, [rest:uri(), $db-name, string-join(distinct-values(map:for-each($lockedBy, function($id, $user){$user})), ', '), $wanted-response], cors:header(()))
  } catch lcks:held {
    error(xs:QName('response-codes:_422'),
                   'You cannot lock entries in file '||$db-name||'.xml',
                   'Entry is currently locked by "'||$err:value('user')||'"')
  }
};

declare %private function _:getUserNameFromAuthorization($auth_header as xs:string) as xs:string {
  let $name_pw := tokenize(util:basic-auth-decode($auth_header), ':')
  (: Digest username="UserNameFromAuthorization", .... :)
  return $name_pw[1]
};

declare
  %private
function _:fileAsXML($dict_name as xs:string, $db-name as xs:string) {
prof:sleep(5000),
if ($dict_name ne $db-name) then
util:eval(``[
(# db:copynode false #) {
  collection($db-name)
}]``, (), 'fileAsXML_getCollection') else (
  let $skel := util:eval(``[collection('`{$db-name}`__skel')]``, (), 'fileAsXML_getSkel'),
      $includes := parse-xml-fragment(serialize($skel//processing-instruction())
        => replace('<?','<','q')
        => replace('?>','/>','q'))
  return $skel update {
    for $pi at $pos in .//processing-instruction()
    let $xpath := data($includes/*[$pos]/@xpath),
        $collection-name-regex := data($includes/*[$pos]/@collection-name-regex),
        $data := util:eval(``[declare namespace tei = "http://www.tei-c.org/ns/1.0";
          db:list()[matches(.,'`{$collection-name-regex}`')]!collection(.)`{$xpath}`]``,
          (), 'fileAsXML_getData'||$pos)
    return replace node $pi with $data
  }
)
};
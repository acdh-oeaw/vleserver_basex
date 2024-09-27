(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/dicts';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace users = 'https://www.oeaw.ac.at/acdh/tools/vle/users' at 'users.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache" at 'data/cache.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at 'data/profile.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)
import module namespace functx = "http://www.functx.com";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace perm = "http://basex.org/modules/perm";

declare variable $_:enable_trace := false();

(:~
 : A list of all dictionaries available on this server.
 :
 : Please note that a client sending Accept application/vnd.wde.v2+json
 : is required to provide credentials. Use application/json or
 : application/hal+json for unrestricted read access.
 : @param $pageSize Number of entries to return per request
 : @param $page The page page to return based on the given pageSize
 : @return A JSON HAL based list of dictionaries. If pageSize is 10 or less the
 :         individual entries are included.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')
    %rest:produces('application/problem+xml')
function _:getDicts($pageSize as xs:integer, $page as xs:integer) {
  let $start := prof:current-ns(),
      $dicts := util:eval(``[db:list()[ends-with(., '__prof') or . = 'dict_users']!replace(., '__prof', '')]``, (), 'get-list-of-dict-profiles'),
      $dicts_as_documents := $dicts!json-hal:create_document(xs:anyURI(util:uri()||.), <name>{.}</name>)
  return api-problem:or_result($start, json-hal:create_document_list#6, [util:uri(), 'dicts', array{$dicts_as_documents}, $pageSize, count($dicts), $page], cors:header(()))
};

(:~
 : Creates a new dictionary.
 : @param $data JSON describing the new dictionary.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return 201 Created
 :)
declare
    %rest:POST('{$data}') 
    %rest:path('/restvle/dicts')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')    
    %test:consumes('application/json')
    %test:arg("data", '{ "name": "some_name" }')
function _:createDict($data, $content-type as xs:string, $wanted-response as xs:string) as item()+ {
  let $start := prof:current-ns(),
      $checkResponse := if ($wanted-response = "application/vnd.wde.v2+json") then true()
        else error(xs:QName('response-codes:_403'),
         'Only wde.v2 aware clients allowed',
         'Accept has to be application/vnd.wde.v2+json.&#x0a;'||
         'Accept was :'||$wanted-response),  
      $checkContentType := if ($content-type = 'application/json') then true()
        else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),      
      (: $data is an element(json) :)
      $checkNameIsSupplied := if (exists($data/json/name)) then true()      
        else error(xs:QName('response-codes:_422'),
         'Wrong JSON object',
         'Need a { "name": "some_name" } object.&#x0a;'||
         'JSON was: '||serialize($data, map{'method': 'json'})),
      $checkDictUsersAlreadyExists := if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users') or
                                          $data/json/name = 'dict_users') then true()
        else error(xs:QName('response-codes:_422'),
         'User directory does not exist',
         'You need to create the special dict_users first')
      return (users:check_global_super_user(),
          util:eval(``[declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
if (db:exists("`{$data/json/name}`__prof")) then
  error(xs:QName('response-codes:_409'),
        'Dictionary "`{$data/json/name}`" already exists')
else if ("`{$data/json/name}`" = 'dict_users') then
  db:create("dict_users", <users/>, "dict_users.xml")
else
  db:create("`{$data/json/name}`__prof", <profile/>, "`{$data/json/name}`.xml")
]``, (), 'try-create-dict', true()),
        api-problem:result($start,
        <problem xmlns="urn:ietf:rfc:7807">
          <type>https://tools.ietf.org/html/rfc7231#section-6</type>
          <title>{$api-problem:codes_to_message(201)}</title>
          <status>201</status>
        </problem>, cors:header(())))
};

(:~
 : A list of all connecting URIs for a particular dictionary.
 :
 : Please note that a client sending Accept application/vnd.wde.v2+json
 : is required to provide credentials. Use application/json or
 : application/hal+json for unrestricted read access.
 : @param $dict_name Name of an existing dictionary
 : @return A JSON HAL based list of connecting URIs.
 :)
(: Get dict_name -> ganzes dict, RFC 7233, Accept-Ranges: bytes, bytes für eine bestimmte Menge entries? :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/{$dict_name}')
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')    
function _:getDictDictName($dict_name as xs:string) as item()+ {
  let $start := prof:current-ns()
  return if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-exists')) then
    let $profile := profile:get($dict_name),
        $query-templates := profile:get-query-templates($profile),
        $db-names := profile:get-list-of-data-dbs($profile),
        $entries-are-cached := profile:use-cache($profile)
    return api-problem:or_result($start, json-hal:create_document_list#6, [util:uri(), '__', [
    json-hal:create_document(xs:anyURI(util:uri()||'/entries'), (<note>all entries</note>,
    <queryTemplates type="array">{map:keys($query-templates)!<_>{.}</_>}</queryTemplates>,
    <dbNames type="array">{$db-names!<_>{.}</_>}</dbNames>,
    if ($entries-are-cached) then <cache>{$entries-are-cached}</cache> else ())),
    json-hal:create_document(xs:anyURI(util:uri()||'/users'), <note>all users with access to this dictionary</note>),
    json-hal:create_document(xs:anyURI(util:uri()||'/files'), <note>all files that make up this dictionary</note>)], 2, 2, 1], cors:header(()))
  else
  error(xs:QName('response-codes:_404'),
                 $api-problem:codes_to_message(404))
};


(:~
 : A list of all connecting URIs for the special dict_users dictionary.
 : @return A JSON HAL based list of connecting URIs. (/users)
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/dict_users')
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')  
function _:getDictDictNameDictUsers() {
  api-problem:or_result(prof:current-ns(), json-hal:create_document_list#6, [util:uri(), '_', [
    json-hal:create_document(xs:anyURI(util:uri()||'/users'), <note>all users with access to this dictionary</note>)], 1, 1, 1], cors:header(()))  
};

(:~
 : Remove a dictionary.
 : 
 : Removes all the databases making up a dictionary including the changes history.
 : Basically any dictionary starting with $dict_name is deleted.
 : Also all users entries for this dictionary are removed.
 : Can also remove dict_users if it is the last remaining dictionary
 : @param $dict_name Name of an existing dictionary
 : @return 204 No Content
 :)
declare
    %rest:DELETE
    %rest:path('/restvle/dicts/{$dict_name}')
    %rest:header-param('Authorization', '{$auth_header}', '')
    %updating
(: This function is meant to have a global write lock. :)
function _:deleteDictDictName($dict_name as xs:string, $auth_header as xs:string) {
  let $start := prof:current-ns(),
      $name_pw := tokenize(util:basic-auth-decode($auth_header), ':')
  return if ($auth_header = '') then
    error(xs:QName('response-codes:_401'), $api-problem:codes_to_message(401))
  else if (exists(collection('dict_users')//user[@name = $name_pw[1] and @dict = $dict_name and @type='su'])) then
  if ($dict_name = 'dict_users' and exists(db:list()[ends-with(., '__prof')])) then
    error(xs:QName('response-codes:_422'), 'You cannot delete dict_users if other dictionaries exist')
  else
  (: Draft: need to look up all the dbs in profile. :)
  for $db in db:list()[matches(., '^'||$dict_name)]
  return (
    db:drop($db), 
    delete node collection('dict_users')//user[@dict=$dict_name],
    update:output(api-problem:result($start,
    <problem xmlns="urn:ietf:rfc:7807">
       <type>https://tools.ietf.org/html/rfc7231#section-6</type>
       <title>{$api-problem:codes_to_message(204)}</title>
       <status>204</status>
    </problem>, cors:header(())
  )))
  else  (: User is no system superuser :)
    error(xs:QName('response-codes:_403'),
                   'Wrong username and password')
};

(:~
 : Creates a backup of a dictionary.
 : @param $dict_name Name of an existing dictionary
 : @param $data Unused.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return 201 Created
 :)
declare
    %rest:POST
    %rest:path('/restvle/dicts/{$dict_name}/backup')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:header-param('Authorization', '{$auth_header}', '')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:consumes('application/json')
    %test:arg("data", '{ }')
function _:createDictBackup($dict_name as xs:string, $content-type as xs:string, $wanted-response as xs:string, $auth_header as xs:string) as item()+ {
  let $start := prof:current-ns(),
      $checkResponse := if ($wanted-response = "application/vnd.wde.v2+json") then true()
        else error(xs:QName('response-codes:_403'),
         'Only wde.v2 aware clients allowed',
         'Accept has to be application/vnd.wde.v2+json.&#x0a;'||
         'Accept was :'||$wanted-response),
      $name_pw := tokenize(util:basic-auth-decode($auth_header), ':'),
      $checkUserIsSUForThisDict := if (exists(collection('dict_users')//user[@name = $name_pw[1] and @dict = $dict_name and @type='su'])) then true()
        else error(xs:QName('response-codes:_403'),
         'You are not allowed to start a backup',
         'Only super users of this dictionary are allowed to start a backup'),   
      $checkContentType := if ($content-type = 'application/json') then true()
        else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),
      $checkDictUsersAlreadyExists := if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users')) then true()
        else error(xs:QName('response-codes:_422'),
         'User directory does not exist',
         'You need to create the special dict_users first'),
      $profile := profile:get($dict_name),
      $backupScripts := (profile:get-list-of-data-dbs($profile)!``[db:create-backup("`{.}`")]``, ``[db:create-backup("`{$dict_name}`__prof")]``) 
      return (util:evals($backupScripts, (), 'try-create-dict-backup', true()),
        api-problem:result($start,
        <problem xmlns="urn:ietf:rfc:7807">
          <type>https://tools.ietf.org/html/rfc7231#section-6</type>
          <title>{$api-problem:codes_to_message(201)}</title>
          <status>201</status>
        </problem>, cors:header(())))
};

(:~
 : Restore a new dictionary from a backup.
 : @param $data JSON describing the new dictionary.
 : @param $content-type Required to be application/json else returns 415.
 : @param $wanted-response Required to be application/vnd.wde.v2+json else returns 403.
 : @error 403 if Accept is not application/vnd.wde.v2+json
 : @error 415 if Content-Type is not application/json
 : @error 422 if the supplied JSON is incorrect 
 : @return 201 Created
 :)
declare
    %rest:POST('{$data}') 
    %rest:path('/restvle/dicts/restore')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:consumes('application/json')
    %test:arg("data", '{ "name": "some_name" }')
function _:restoreDict($data, $content-type as xs:string, $wanted-response as xs:string) as item()+ {
  let $start := prof:current-ns(),
      $checkResponse := if ($wanted-response = "application/vnd.wde.v2+json") then true()
        else error(xs:QName('response-codes:_403'),
         'Only wde.v2 aware clients allowed',
         'Accept has to be application/vnd.wde.v2+json.&#x0a;'||
         'Accept was :'||$wanted-response),  
      $checkContentType := if ($content-type = 'application/json') then true()
        else error(xs:QName('response-codes:_415'),
         'Content-Type needs to be application/json',
         'Content-Type was: '||$content-type),      
      (: $data is an element(json) :)
      $checkNameIsSupplied := if (exists($data/json/name)) then true()      
        else error(xs:QName('response-codes:_422'),
         'Wrong JSON object',
         'Need a { "name": "some_name" } object.&#x0a;'||
         'JSON was: '||serialize($data, map{'method': 'json'})),
      $checkDictUsersAlreadyExists := if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users') or
                                          $data/json/name = 'dict_users') then true()
        else error(xs:QName('response-codes:_422'),
         'User directory does not exist',
         'You need to create the special dict_users first')
      return (users:check_global_super_user(),
          util:eval(``[db:restore("`{$data/json/name}`__prof")]``, (), 'try-restore-dict_profile', true()),
          let $profile := profile:get($data/json/name),
              $restoreScripts := (profile:get-list-of-data-dbs-and-backups($profile)!
          ``[db:restore("`{.}`")]``, if (profile:use-cache($profile)) then cache:cache-all-entries($data/json/name) else ())
          return util:evals($restoreScripts, (), 'try-restore-all-dbs-for-dict', true()),
        api-problem:result($start,
        <problem xmlns="urn:ietf:rfc:7807">
          <type>https://tools.ietf.org/html/rfc7231#section-6</type>
          <title>{$api-problem:codes_to_message(201)}</title>
          <status>201</status>
        </problem>, cors:header(())))
};
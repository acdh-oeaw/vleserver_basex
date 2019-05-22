xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/dicts';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)
import module namespace functx = "http://www.functx.com";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace perm = "http://basex.org/modules/perm";

declare variable $_:enable_trace := false();

declare
    %rest:GET
    %rest:path('restvle/dicts')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDicts($pageSize as xs:integer, $page as xs:integer) {
  let $dicts := util:eval(``[db:list()[ends-with(., '__prof') or . = 'dict_users']!replace(., '__prof', '')]``, (), 'get-list-of-dict-profiles'),
      $dicts_as_documents := $dicts!json-hal:create_document(xs:anyURI(rest:uri()||'/'||.), <name>{.}</name>)
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'dicts', array{$dicts_as_documents}, $pageSize, count($dicts), $page])
};

declare
    %rest:POST('{$data}') 
    %rest:path('restvle/dicts')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
function _:createDict($data, $content-type as xs:string, $wanted-response as xs:string) {
  let $checkResponse := if ($wanted-response = "application/vnd.wde.v2+json") then true()
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
      return (_:check_global_super_user(),
          util:eval(``[declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
if (db:exists("`{$data/json/name}`__prof")) then
  error(xs:QName('response-codes:_409'),
        'Dictionary "`{$data/json/name}`" already exists')
else if ("`{$data/json/name}`" = 'dict_users') then
  db:create("dict_users", <users/>, "dict_users.xml")
else
  db:create("`{$data/json/name}`__prof", <empty/>, "`{$data/json/name}`.xml")
]``, (), 'try-create-dict', true()),
        api-problem:result(
        <problem xmlns="urn:ietf:rfc:7807">
          <type>https://tools.ietf.org/html/rfc7231#section-6</type>
          <title>{$api-problem:codes_to_message(201)}</title>
          <status>201</status>
        </problem>))
};

declare function _:check_global_super_user() as empty-sequence() {
  util:eval(``[ declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
  let $name_pw := tokenize("`{convert:binary-to-string(xs:base64Binary(replace(request:header('Authorization', ''), '^Basic ', '')))}`", ':'),
      $user_tag := try { collection('dict_users')/users/user[@name=$name_pw[1] and upper-case(@pw)=upper-case($name_pw[2]) and 
                                                       @type="su" and @dict = "dict_users"] }
                   catch err:FODC0002 { (: Until dict_users is created everyone is superuser :) true() }          
      return if (exists($user_tag)) then () else
        error(xs:QName('response-codes:_403'),
                       'Only global super users may create dictionaries.') ]``, (), 'check-global-super-user')
};

(: Get dict_name -> ganzes dict, RFC 7233, Accept-Ranges: bytes, bytes für eine bestimmte Menge entries? :)

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}')
function _:getDictDictName($dict_name as xs:string) {
  if (util:eval(``[db:exists("`{$dict_name}`__prof")]``, (), 'check-dict-exists')) then 
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/entries'), <note>all entries</note>),
    json-hal:create_document(xs:anyURI(rest:uri()||'/users'), <note>all users with access to this dictionary</note>)], 2, 2, 1])
  else
  error(xs:QName('response-codes:_404'),
                 $api-problem:codes_to_message(404))
};

declare
    %rest:GET
    %rest:path('restvle/dicts/dict_users')
function _:getDictDictNameDictUsers() {
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/users'), <note>all users with access to this dictionary</note>)], 1, 1, 1])  
};

declare
    %rest:DELETE
    %rest:path('restvle/dicts/{$dict_name}')
    %rest:header-param('Authorization', '{$auth_header}', '')
    %updating
(: This function is meant to have a global write lock. :)
function _:deleteDictDictName($dict_name as xs:string, $auth_header as xs:string) {
  let $name_pw := tokenize(convert:binary-to-string(xs:base64Binary(replace($auth_header, '^Basic ', ''))), ':')
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
    update:output(api-problem:result(
    <problem xmlns="urn:ietf:rfc:7807">
       <type>https://tools.ietf.org/html/rfc7231#section-6</type>
       <title>{$api-problem:codes_to_message(204)}</title>
       <status>204</status>
    </problem>
  )))
  else  (: User is no system superuser :)
    error(xs:QName('response-codes:_403'),
                   'Wrong username and password')
};
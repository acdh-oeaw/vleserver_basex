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

declare variable $_:enable_trace := false();

declare
    %perm:check('restvle/dicts', '{$_}')
function _:checkPermissions($_ as map(*)) {
  if ($_('method') ne 'GET' or
      request:header('Accept', '') eq 'application/vnd.wde.v2+json')
  then
    if (db:exists('dict_users')) then
      let $name_pw := tokenize(convert:binary-to-string(xs:base64Binary(replace($_('authorization'), '^Basic ', ''))), ':'),
          $user_tag := collection('dict_users')/users/user[@name=$name_pw[1] and upper-case(@pw)=upper-case($name_pw[2])],
          $dict := replace($_('path'), '^/restvle/dicts/?([^/]*).*$', '$1')
      return if (exists($user_tag[if ($dict ne "") then @dict = $dict else true()])) then () else
        error(xs:QName('response-codes:_403'),
                       'Wrong username and password')
     else()
  else ()
};

declare
    %rest:GET
    %rest:path('restvle/dicts')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDicts($pageSize as xs:integer, $page as xs:integer) {
  let $dicts := util:eval(``[db:list()[ends-with(., '__prof')]!replace(., '__prof', '')]``, (), 'get-list-of-profile'),
      $dicts_as_documents := $dicts!json-hal:create_document(xs:anyURI(rest:uri()||'/'||.), <name>{.}</name>)
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'dicts', array{$dicts_as_documents}, $pageSize, count($dicts), $page])
};

declare
    %rest:POST('{$data}') 
    %rest:path('restvle/dicts')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
function _:createDict($data, $content-type as xs:string, $wanted-response as xs:string) {
  if ($wanted-response = "application/vnd.wde.v2+json") then
    if ($content-type = 'application/json') then
      (: in this case $data is an element(json) :)
      if (exists($data/json/name)) then
        if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users')) then
          util:eval(``[
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
if (db:exists("`{$data/json/name}`__prof")) then
  error(xs:QName('response-codes:_406'),
        'Dictionary "`{$data/json/name}`" already exists')
else
  db:create("`{$data/json/name}`__prof", <empty/>, "`{$data/json/name}`.xml")
]``, (), 'try-create-dict', true())
        else if ($data/json/name ne "dict_users")
        then error(xs:QName('response-codes:_422'),
                   'User directory does not exist',
                   'You need to create the special dict_users first')
        else util:eval(``[db:create("dict_users",                                    
<users>
  <user name="admin"
        dict="dict_users"
        type="su"
        pw="8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918"
        dt="2000-01-01T00:00:00"/>
</users>, "dict_users.xml")]``,
                       (), 'create_dict_users', true())
      else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               'Need a { "name": "some_name" } object.&#x0a;'||
               'JSON was: '||serialize($data, map{'method': 'json'}))
    else 
      error(xs:QName('response-codes:_415'),
            'Content-Type needs to be application/json',
            'Content-Type was: '||$content-type)
 else
   error(xs:QName('response-codes:_403'),
         'Only wde.v2 aware clients allowed',
         'Accept has to be application/vnd.wde.v2+json.&#x0a;'||
         'Accept was :'||$wanted-response)
};

(: Get dict_name -> ganzes dict, RFC 7233, Accept-Ranges: bytes, bytes für eine bestimmte Menge entries? :)

declare
    %rest:GET
    %rest:path('restvle/dicts/{$dict_name}')
function _:getDictDictName($dict_name as xs:string) {
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/entries'), <note>all entries</note>),
    json-hal:create_document(xs:anyURI(rest:uri()||'/users'), <note>all users with access to this dictionary</note>)], 2, 2, 1])
};

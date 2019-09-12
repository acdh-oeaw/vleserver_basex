(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/users';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

declare variable $_:enable_trace := false();

(:~
 : List users.
 :)
declare
    %rest:GET
    %rest:path('/restvle/dicts/dict_users/users')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
    %rest:produces('application/json')
    %rest:produces('application/hal+json')
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')   
    %rest:produces('application/problem+xml')
function _:getDictDictUserUsers($pageSize as xs:integer, $page as xs:integer) {
  let $start := prof:current-ns(),
      $users := try { util:eval(``[collection("dict_users")/users/user]``, (), 'get-users') }
      catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      },
      (: FIXME: get the ids right. For $u at $p in $users where $p >= (($page - 1) * $pageSize) + 1 and $p <= (($page - 1) * $pageSize) + $pageSize ... :)
      $entries_as_documents := subsequence($users, (($page - 1) * $pageSize) + 1, $pageSize)!_:userAsDocument(try {xs:anyURI(rest:uri()||'/'||./position())} catch basex:http {xs:anyURI('urn:local')}, .)
  return api-problem:or_result($start, json-hal:create_document_list#6, [rest:uri(), 'users', array{$entries_as_documents}, $pageSize, count($users), $page], cors:header(()))
};

declare
  %private
function _:userAsDocument($_self as xs:anyURI, $user as element()?) {
  json-hal:create_document($_self, (
    <id>{$user/position()}</id>,
    <userID>{data($user/@name)}</userID>,
    <dict>{data($user/@dict)}</dict>,
    <type>{data($user/@type)}</type>,
    (: Compatibility stuff, delete when possible :)
    <table>{data($user/@dict)}</table>,
    <read>y</read>,
    <write>{if ($user/@type = 'ro') then 'n' else 'y'}</write>,
    <writeown>{if ($user/@type = 'su') then 'n' else 'y'}</writeown>))
};

(:~
 : Create a user.
 :)
declare
    %rest:POST('{$userData}')
    %rest:path('/restvle/dicts/dict_users/users')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
    %rest:produces('application/vnd.wde.v2+json')
    %rest:produces('application/problem+json')  
    %rest:produces('application/problem+xml')
    %test:arg("userData", '{
  "id": "The internal ID. When creating a new user this will be filled in automatically.",
  "userID": "The user id or username.",
  "pw": "The password for that user and that table.",
  "read": "Whether the user has read access.",
  "write": "Whether the user has write access.",
  "writeown": "Whether the user may change entries that dont belong to her.",
  "table": "A table name. Will only be returned on administrative queries on the special dict_users storage."
}')
function _:createUser($userData, $content-type as xs:string, $wanted-response as xs:string) {
  let $start := prof:current-ns()
  return if ($wanted-response = "application/vnd.wde.v2+json") then
    if ($content-type = 'application/json') then
      (: in this case $data is an element(json) :)
      if (exists($userData/json/id) and
          exists($userData/json/userID) and
          exists($userData/json/pw) and
          exists($userData/json/table) and
          exists($userData/json/read) and
          exists($userData/json/write) and
          exists($userData/json/writeown)) then
        if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users')) then
        let $check_first_user_has_access_to_dict_users :=
            if ($userData/json/table ne 'dict_users' and 
                util:eval(``[not(exists(collection("dict_users")/users/*))]``, (), 'check-dict-users')) then
              error(xs:QName('response-codes:_422'),
                   'There has to be a dict_users user first!',
                   'You need to create a user for dict_users first.') else (),
            (: The three rights cannot be expressed any shorter else they will
               appear in document order not ordered as expressed here. :)
            $type := switch (string-join(($userData/json/read,
                                          $userData/json/write,
                                          $userData/json/writeown), ''))
                       case 'yyn' return 'su'
                       case 'yyy' return ()
                       case 'ynn' return 'ro'
                       default return 'ro',
            $userTag := <user name="{$userData/json/userID}"
                              dict="{$userData/json/table}"
                              pw="{$userData/json/pw}"
                              dt="{format-dateTime(current-dateTime(), '[Y1111]-[M11]-[D11]T[H11]:[m11]:[s11]')}">
                        {if ($type) then attribute {'type'}{$type}}
                        </user>
        return api-problem:or_result($start, util:eval#4, [``[
            insert node `{serialize($userTag)}` as last into collection('dict_users')/users,            
            update:output(`{serialize($userData)}` transform with {(replace node ./id with element {'id'} {count(collection('dict_users')/users/*) + 1}, delete node ./pw)})
        ]``, (), 'write-new-user', true()], cors:header(()))
        else error(xs:QName('response-codes:_422'),
                   'User directory does not exist',
                   'You need to create the special dict_users first')
      else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               ``[Need a {
  "id": "The internal ID. When creating a new user this will be filled in automatically.",
  "userID": "The user id or username.",
  "pw": "The password for that user and that table.",
  "read": "Whether the user has read access.",
  "write": "Whether the user has write access.",
  "writeown": "Whether the user may change entries that don't belong to her.",
  "table": "A table name. Will only be returned on administrative queries on the special dict_users storage."
} object.&#x0a;]``||
               'JSON was: '||serialize($userData, map{'method': 'json'}))
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

declare
   %rest:GET
   %rest:path('/restvle/dicts/dict_users/users/{$userName_or_id}')
   %rest:produces('application/json')
   %rest:produces('application/hal+json')
   %rest:produces('application/vnd.wde.v2+json')
   %rest:produces('application/problem+json')   
   %rest:produces('application/problem+xml')
function _:getDictDictNameUser($userName_or_id as xs:string) {
  let $start := prof:current-ns(),
      $users := if ($userName_or_id castable as xs:integer) then util:eval(``[collection("dict_users")/users/user[`{$userName_or_id}`]]``, (), 'get-users')
                else util:eval(``[collection("dict_users")/users/user[@name = "`{$userName_or_id}`"]]``, (), 'get-users')
  return if (not(exists($users))) then error(xs:QName('response-codes:_404'), $api-problem:codes_to_message(404))
         else api-problem:or_result($start, _:userAsDocument#2, [rest:uri(), $users], cors:header(()))
};
(:~
 : Remove a user.
 :)
declare
  %rest:DELETE
  %rest:path('/restvle/dicts/dict_users/users/{$userName_or_id}')
  %updating
(: write locks dict_users :)
function _:deleteDictDictNameUser($userName_or_id as xs:string) {
  let $start := prof:current-ns()
  (: TODO check that there is one dict_users user left before deleting a dict_users user
     or that this is the last dict_users user :)
  return (
  if ($userName_or_id castable as xs:integer) then delete node collection('dict_users')//user[xs:integer($userName_or_id)]
  else delete node collection('dict_users')//user[@name = $userName_or_id],
  update:output(api-problem:result($start,
    <problem xmlns="urn:ietf:rfc:7807">
       <type>https://tools.ietf.org/html/rfc7231#section-6</type>
       <title>{$api-problem:codes_to_message(204)}</title>
       <status>204</status>
    </problem>, cors:header(())
  ))
  )
};

(:~
 : Disables these methods for dict_users.
 : @return Unconditionally returns.
 :)
declare
    %rest:GET
    %rest:POST
    %rest:path('/restvle/dicts/dict_users/entries')
function _:getDictDictUserEntries404() {
  error(xs:QName('response-codes:_404'),
                       'Not found')  
};

(:~
 : Disables these methods for dict_users.
 : @param $_ ignored
 : @return Unconditionally returns 404.
 :)
declare
    %rest:GET
    %rest:PUT
    %rest:DELETE
    %rest:path('/restvle/dicts/dict_users/entries/{$_}')
function _:getDictDictUserEntry404($_) {
  error(xs:QName('response-codes:_404'),
                       'Not found')  
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
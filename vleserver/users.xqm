xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/users';

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
    %rest:path('restvle/dicts/dict_users/entries')
    %rest:query-param("page", "{$page}", 1)
    %rest:query-param("pageSize", "{$pageSize}", 25)
function _:getDictDictUserEntries($pageSize as xs:integer, $page as xs:integer) {
  let $users := try { util:eval(``[collection("dict_users")/users/user]``, (), 'get-users') }
      catch err:FODC0002 {
        error(xs:QName('response-codes:_404'),
                       'Not found',
                       $err:additional)
      },
      $entries_as_documents := subsequence($users, (($page - 1) * $pageSize) + 1, $pageSize)!_:userAsDocument(try {xs:anyURI(rest:uri()||'/'||data(.))} catch basex:http {xs:anyURI('urn:local')}, .)
  return api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), 'users', array{$entries_as_documents}, $pageSize, count($users), $page])
};

declare
  %private
function _:userAsDocument($_self as xs:anyURI, $user as element()?) {
  json-hal:create_document($_self, (
    <id>{$user/@name}</id>,
    <table>{$user/@table}</table>,
    <read>y</read>,
    <write>{if ($user/@type = 'ro') then 'n' else 'y'}</write>,
    <writeown>{if ($user/@type = 'su') then 'n' else 'y'}</writeown>))
};

declare
    %rest:POST('{$userData}')
    %rest:path('restvle/dicts/dict_users/entries')
    %rest:header-param("Content-Type", "{$content-type}", "")
    %rest:header-param("Accept", "{$wanted-response}", "")
function _:createUser($userData, $content-type as xs:string, $wanted-response as xs:string) {
  if ($wanted-response = "application/vnd.wde.v2+json") then
    if ($content-type = 'application/json') then
      (: in this case $data is an element(json) :)
      if (exists($userData/json/id) and
          exists($userData/json/pw) and
          exists($userData/json/table) and
          exists($userData/json/read) and
          exists($userData/json/write) and
          exists($userData/json/writeown)) then
        if (util:eval(``[db:exists("dict_users")]``, (), 'check-dict-users')) then
        let $type := switch (string-join($userData/json/(read, write, writeown), ''))
                       case 'yyn' return 'su'
                       case 'yyy' return ()
                       case 'ynn' return 'ro'
                       default return 'ro',
            $userTag := <user name="{$userData/json/id}"
                              dict="{$userData/json/table}"
                              pw="{$userData/json/pw}"
                              dt="{format-dateTime(current-dateTime(), '[Y1111]-[M11]-[D11]T[H11]:[m11]:[s11]')}">
                        {if ($type) then attribute {'type'}{$type}}
                        </user>
        return (util:eval(``[
            insert node `{serialize($userTag)}` as last into collection('dict_users')/users
        ]``, (), 'write-new-user', true()),
          error(xs:QName('response-codes:_201'), 'Created'))
        else error(xs:QName('response-codes:_422'),
                   'User directory does not exist',
                   'You need to create the special dict_users first')
      else error(xs:QName('response-codes:_422'),
               'Wrong JSON object',
               ``[Need a {
  "id": "The internal ID. When creating a new user this will be filled in automatically.",
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
   %rest:path('restvle/dicts/dict_users/entries/{$user}')
function _:getDictDictNameEntry($userName as xs:string) {
  let $user := util:eval(``[collection("dict_users")/users/user[@name = "`{$userName}`"]]``, (), 'get-users')
  return api-problem:or_result(_:userAsDocument#2, [rest:uri(), $user/@name, $user])
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
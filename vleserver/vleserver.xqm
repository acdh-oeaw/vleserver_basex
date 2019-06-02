(:~
 : API Problem and JSON HAL based API for editing dictionary like XML datasets.
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle';

import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace req = "http://exquery.org/ns/request";
import module namespace json-hal = 'https://tools.ietf.org/html/draft-kelly-json-hal-00' at 'json-hal.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)
import module namespace openapi="https://lab.sub.uni-goettingen.de/restxqopenapi" at "../3rd-party/openapi/content/openapi.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();

declare
    %perm:check('/restvle/dicts', '{$_}')
function _:checkPermissions($_ as map(*)){
  let $dict := replace($_('path'), '^/restvle/dicts/?([^/]*).*$', '$1'),
      $list := replace($_('path'), '^/restvle/dicts/?([^/]+/([^/]+)).*$', '$2'),
      $accept_check := if (not(tokenize(request:header('Accept', ''), '[,;]') = ('',
        'application/vnd.wde.v2+json',
        'application/hal+json',
        'application/json',
        'application/xml',
        '*/*'))) then
      error(xs:QName('response-codes:_406'),
            $api-problem:codes_to_message(406),
            'Don&apos;t know how to generate '||request:header('Accept', '')||' response.') else ()
  (: TODO perhaps stop if ($_('method') ne 'GET' and request:header('Accept', '') ne 'application/vnd.wde.v2+json') :)
  (: dicts and dicts/dict_users always ok, users is not :)
  return
  (: if ($dict = ('', 'dict_users') and not($list = ('users'))) then () else :)
  if ($_('method') = ('OPTIONS')) then () (: Allway permitted for CORS. :)
  else if (not($_('method') = ('GET')) or
      request:header('Accept', '') eq 'application/vnd.wde.v2+json' or
      $list = ('users'))       
  then
    if (db:exists('dict_users')) then
      if (not(exists($_('authorization'))) and exists(collection('dict_users')/users/user)) then
        error(xs:QName('response-codes:_401'), $api-problem:codes_to_message(401))
      else
      let $name_pw := tokenize(convert:binary-to-string(xs:base64Binary(replace($_('authorization'), '^Basic ', ''))), ':'),
          $user_tag := collection('dict_users')/users/user[@name=$name_pw[1] and upper-case(@pw)=upper-case($name_pw[2])]          
      return if ((not(exists(collection('dict_users')/users/user)) and $dict = ("", "dict_users")) or
                 exists($user_tag[if ($dict ne "") then @dict = $dict else true()])) then () else
        error(xs:QName('response-codes:_403'),
                       'Wrong username and password')
     else ()
  else ()
};

(:~
 : A static collection showing valid next URLs.
 : @return A JSON HAL based list of documents. If pageSize is 10 or less the
 :         individual entries are included.
 :)
declare
    %rest:GET
    %rest:path('/restvle')
    %rest:produces('application/json')
    (: %rest:produces('application/problem+json') :)   
    (: %rest:produces('application/problem+xml') :)
function _:getRoot() as item()+ {
  api-problem:or_result(json-hal:create_document_list#6, [rest:uri(), '_', [
    json-hal:create_document(xs:anyURI(rest:uri()||'/dicts'), <note>all dictionaries</note>)], 1, 1, 1])
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};

declare
    %rest:path('/restvle/openapi.json')
    %rest:produces('application/json')
    %output:media-type('application/json')
function _:getOpenapiJSON() as item()+ {
  openapi:json(file:parent(file:base-dir()))
};
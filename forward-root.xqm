xquery version "3.1";
module namespace _ = "uri:_";
declare namespace rest = "uri:rest";

(:~
 : Redirects to API path.
 : @return rest response
 :)
declare
  %rest:path('')
function _:index-file() as item()+ {
  let $absolute-prefix := if (matches(_:get-base-uri-public(), '/$')) then () else _:get-base-uri-public()||'/'
  return if (exists($absolute-prefix)) then
  <rest:response>
    <http:response status="302">
      <http:header name="Location" value="{$absolute-prefix}restvle/"/>
    </http:response>
  </rest:response>
  else
  <rest:response>
    <http:response status="302">
      <http:header name="Location" value="restvle/"/>
    </http:response>
  </rest:response>
};

declare function _:get-base-uri-public() as xs:string {
    let $forwarded-hostname := if (contains(request:header('X-Forwarded-Host'), ',')) 
                                 then substring-before(request:header('X-Forwarded-Host'), ',')
                                 else request:header('X-Forwarded-Host'),
        $urlScheme := if ((lower-case(request:header('X-Forwarded-Proto')) = 'https') or 
                          (lower-case(request:header('Front-End-Https')) = 'on')) then 'https' else 'http',
        $port := if ($urlScheme eq 'http' and request:port() ne 80) then ':'||request:port()
                 else if ($urlScheme eq 'https' and not(request:port() eq 80 or request:port() eq 443)) then ':'||request:port()
                 else '',
        (: FIXME: this is to naive. Works for ProxyPass / to /exist/apps/cr-xq-mets/project
           but probably not for /x/y/z/ to /exist/apps/cr-xq-mets/project. Especially check the get module. :)
        $xForwardBasedPath := (request:header('X-Forwarded-Request-Uri'), request:path())[1]
    return $urlScheme||'://'||($forwarded-hostname, request:hostname())[1]||$port||$xForwardBasedPath
};
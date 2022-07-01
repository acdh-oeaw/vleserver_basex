xquery version "3.1";

module namespace _ = "https://tools.ietf.org/html/rfc7807";
import module namespace req = "http://exquery.org/ns/request";
import module namespace cors = 'https://www.oeaw.ac.at/acdh/tools/vle/cors' at 'cors.xqm';
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace rfc7807 = "urn:ietf:rfc:7807";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";

declare variable $_:enable_trace external := true();

declare function _:or_result($start-time-ns as xs:integer, $api-function as function(*)*, $parameters as array(*)) as item()+ {
    _:or_result($start-time-ns, $api-function, $parameters, (), ())
};

declare function _:or_result($start-time-ns as xs:integer, $api-function as function(*)*, $parameters as array(*), $header-elements as map(xs:string, xs:string)?) as item()+ {
    _:or_result($start-time-ns, $api-function, $parameters, (), $header-elements)
};

declare function _:or_result($start-time-ns as xs:integer, $api-function as function(*)*, $parameters as array(*), $ok-status as xs:integer?, $header-elements as map(xs:string, xs:string)?) as item()+ {
    try {
        let $ok-status := if ($ok-status > 200 and $ok-status < 300) then $ok-status else 200,
            $ret := apply($api-function, $parameters),
            $timings := if ($ret instance of map(*) and exists($ret?time)) then $ret?time else (),
            $ret := if ($ret instance of map(*) and exists($ret?value)) then $ret?value else $ret
        return if ($ret instance of element(rfc7807:problem)) then _:return_problem($start-time-ns, $ret,$header-elements)
        else        
          (web:response-header(map {'method': 'json'}, $header-elements, map{'message': $_:codes_to_message($ok-status), 'status': $ok-status}),
          _:inject-runtime($start-time-ns, $ret, $timings)
          )
    } catch * {
        let $status-code := if (namespace-uri-from-QName($err:code) eq 'https://tools.ietf.org/html/rfc7231#section-6') then
          let $status-code-from-local-name := replace(local-name-from-QName($err:code), '_', '')
          return if ($status-code-from-local-name castable as xs:integer and 
                     xs:integer($status-code-from-local-name) > 400 and
                     xs:integer($status-code-from-local-name) < 511) then xs:integer($status-code-from-local-name) else 400
        else (500, admin:write-log($err:additional, 'ERROR'))
        return _:return_problem($start-time-ns,
                <problem xmlns="urn:ietf:rfc:7807">
                    <type>{namespace-uri-from-QName($err:code)}</type>
                    <title>{$err:description}</title>
                    <detail>{$err:value}</detail>
                    <instance>{namespace-uri-from-QName($err:code)}/{local-name-from-QName($err:code)}</instance>
                    <status>{$status-code}</status>
                    {if ($_:enable_trace) then <trace>{$err:module}: {$err:line-number}/{$err:column-number}{replace($err:additional, '^.*Stack Trace:', '', 's')}</trace> else ()}
                </problem>, $header-elements)     
    }
};

declare function _:trace-info($description as xs:string, $trace-result as map(xs:string, item()*)) as map(xs:string, item()*) {
  if ($trace-result?value instance of map(*) and $trace-result?value?value)
    then let $times := map:remove($trace-result?value, 'value')
      return map:merge((map{'value': $trace-result?value?value,
             $description: sum($trace-result?time)},
             $times))
    else map{'value': $trace-result?value,
             $description: $trace-result?time}
};

declare function _:return_problem($start-time-ns as xs:integer, $problem as element(rfc7807:problem), $header-elements as map(xs:string, xs:string)?) as item()+ {
let $accept-header := try { req:header("ACCEPT") } catch basex:http { 'application/problem+xml' },
    $header-elements := map:merge(($header-elements, map{'Content-Type': if (matches($accept-header, '[+/]json')) then 'application/problem+json' else if (matches($accept-header, 'application/xhtml\+xml')) then 'application/xml' else 'application/problem+xml'})),
    $error-status := if ($problem/rfc7807:status castable as xs:integer) then xs:integer($problem/rfc7807:status) else 400
return (web:response-header((), $header-elements, map{'message': $problem/rfc7807:title, 'status': $error-status}),
 _:on_accept_to_json($problem)
)   
};

declare function _:result($start-time-ns as xs:integer, $result as element(rfc7807:problem), $header-elements as map(xs:string, xs:string)?) {
  _:or_result($start-time-ns, _:return_result#1, [$result], $header-elements)
};

declare %private function _:return_result($to_return as node()) {
  $to_return
};

declare %private function _:inject-runtime($start as xs:integer, $ret, $timings as map(*)?) {
  if ($ret instance of map(*)) then map:merge(($ret, map {'took': _:runtime($start)}))
  else if ($ret instance of element(json)) then $ret transform with { insert node <took>{_:runtime($start)}</took> as last into .,
  if (exists($timings)) then insert node <timings type='object'>{for $k in map:keys($timings) return element {replace($k, '_', '__') => replace('@', '_0040') => replace(':', '_003a')} {xs:string($timings($k))} }</timings> as last into .}
  else $ret
};

declare %private function _:runtime($start as xs:integer) {
  ((prof:current-ns() - $start) idiv 10000) div 100
};

declare
(: use when there is another error handler :)
(:  %rest:error('Q{https://tools.ietf.org/html/rfc7231#section-6}*') :)
(: use when this is the only error handler :)
  %rest:error('*')
  %rest:error-param("code", "{$code}")
  %rest:error-param("description", "{$description}")
  %rest:error-param("value", "{$value}")
  %rest:error-param("module", "{$module}")
  %rest:error-param("line-number", "{$line-number}")
  %rest:error-param("column-number", "{$column-number}")
  %rest:error-param("additional", "{$additional}")
function _:error-handler($code as xs:string, $description, $value, $module, $line-number, $column-number, $additional) as item()+ {
        let $start-time-ns := prof:current-ns(),
            $origin := try { req:header("Origin") } catch basex:http {'urn:local'},
            $type := try {
              namespace-uri-from-QName(xs:QName($code))
            } catch err:FONS0004 {
              replace($code, '^[^:]+:', '')
            },
            $instance := try {
              namespace-uri-from-QName(xs:QName($code))||"/"||local-name-from-QName(xs:QName($code))
            } catch err:FONS0004 {
              $code
            },
            $status-code := 
          let $status-code-from-local-name := try {replace(local-name-from-QName(xs:QName($code)), '_', '')}
          catch err:FONS0004 {$code}
          return if ($status-code-from-local-name castable as xs:integer and 
                     xs:integer($status-code-from-local-name) >= 400 and
                     xs:integer($status-code-from-local-name) < 511) then xs:integer($status-code-from-local-name) else
                     (500, admin:write-log($additional, 'ERROR'))
        return _:return_problem($start-time-ns,
                <problem xmlns="urn:ietf:rfc:7807">
                    <type>{$type}</type>
                    <title>{$description}</title>
                    <detail>{$value}</detail>
                    <instance>{$instance}</instance>
                    <status>{$status-code}</status>
                    {if ($_:enable_trace) then <trace xml:space="preserve">{replace(replace($additional, '^.*Stopped at ', '', 's'), ':\n.*($|(\n\nStack Trace:(\n)))', '$3')}</trace> else ()}
                </problem>, if (exists($origin)) then map{"Access-Control-Allow-Origin": $origin,
                                "Access-Control-Allow-Credentials": "true"} else ())  
};

declare %private function _:on_accept_to_json($problem as element(rfc7807:problem)) as item() {
  let $objects := string-join($problem//*[*[local-name() ne '_']]/local-name(), ' '),
      $arrays := string-join($problem//*[*[local-name() eq '_']]/local-name(), ' '),
      $accept-header := try { req:header("ACCEPT") } catch basex:http { 'application/problem+xml' }
  return
  if (matches($accept-header, '[+/]json'))
  then json:serialize(<json type="object" objects="{$objects}" arrays="{$arrays}">{$problem/* transform with {delete node @xml:space}}</json>, map {'format': 'direct'})
  else $problem
};

declare variable $_:codes_to_message := map {
    100: 'Continue',
    101: 'Switching Protocols',
    102: 'Processing',

    200: 'OK',
    201: 'Created',
    202: 'Accepted',
    203: 'Non-Authoritative Information',
    204: 'No Content',
    205: 'Reset Content',
    206: 'Partial Content',
    207: 'Multi-Status',
    208: 'Already Reported',
    226: 'IM Used',

    300: 'Multiple Choices',
    301: 'Moved Permanently',
    302: 'Moved Temporarily',
    303: 'See Other',
    304: 'Not Modified',
    305: 'Use Proxy',
    306: 'Switch Proxy',
    307: 'Temporary Redirect',
    308: 'Permanent Redirect',

    400: 'Bad Request',
    401: 'Unauthorized',
    402: 'Payment Required',
    403: 'Forbidden',
    404: 'Not Found',
    405: 'Method Not Allowed',
    406: 'Not Acceptable',
    407: 'Proxy Authentication Required',
    408: 'Request Time-out',
    409: 'Conflict',
    410: 'Gone',
    411: 'Length Required',
    412: 'Precondition Failed',
    413: 'Request Entity Too Large',
    414: 'URI Too Long',
    415: 'Unsupported Media Type',
    416: 'Requested range not satisfiable',
    417: 'Expectation Failed',
    418: 'I’m a teapot',
    420: 'Policy Not Fulfilled',
    421: 'Misdirected Request',
    422: 'Unprocessable Entity',
    423: 'Locked',
    424: 'Failed Dependency',
    425: 'Unordered Collection',
    426: 'Upgrade Required',
    428: 'Precondition Required',
    429: 'Too Many Requests',
    431: 'Request Header Fields Too Large',
    444: 'No Response',
    449: 'Retry',
    451: 'Unavailable For Legal Reasons',
    499: 'Client Closed Request',

    500: 'Internal Server Error',
    501: 'Not Implemented',
    502: 'Bad Gateway',
    503: 'Service Unavailable',
    504: 'Gateway Time-out',
    505: 'HTTP Version not supported',
    506: 'Variant Also Negotiates',
    507: 'Insufficient Storage',
    508: 'Loop Detected',
    509: 'Bandwidth Limit Exceeded',
    510: 'Not Extended',
    511: 'Network Authentication Required'
};
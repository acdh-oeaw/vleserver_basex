xquery version "3.0";

module namespace _ = "https://tools.ietf.org/html/rfc7807";
import module namespace req = "http://exquery.org/ns/request";

declare namespace rfc7807 = "urn:ietf:rfc:7807";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";

declare variable $_:enable_trace external := true();

declare function _:or_result($api-function as function(*)*, $parameters as array(*)) as item()+ {
    _:or_result($api-function, $parameters, (), ())
};
declare function _:or_result($api-function as function(*)*, $parameters as array(*), $header-elements as map(xs:string, xs:string)) as item()+ {
    _:or_result($api-function, $parameters, (), $header-elements)
};

declare function _:or_result($api-function as function(*)*, $parameters as array(*), $ok-status as xs:integer?, $header-elements as map(xs:string, xs:string)?) as item()+ {
    try {
        let $ok-status := if ($ok-status > 200 and $ok-status < 300) then $ok-status else 200,
            $ret := apply($api-function, $parameters)
        return if ($ret instance of element(rfc7807:problem)) then _:return_problem($ret,$header-elements)
        else        
          (<rest:response>
              <http:response status="{$ok-status}" message="{$_:codes_to_message($ok-status)}">
              {_:map_to_header_elements($header-elements)}
              </http:response>
          </rest:response>,
          $ret
          )
    } catch * {
        let $status-code := if (namespace-uri-from-QName($err:code) eq 'https://tools.ietf.org/html/rfc7231#section-6') then
          let $status-code-from-local-name := replace(local-name-from-QName($err:code), '_', '')
          return if ($status-code-from-local-name castable as xs:integer and 
                     xs:integer($status-code-from-local-name) > 400 and
                     xs:integer($status-code-from-local-name) < 500) then xs:integer($status-code-from-local-name) else 400
        else 400        
        return _:return_problem(
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

declare function _:return_problem($problem as element(rfc7807:problem), $header-elements as map(xs:string, xs:string)?) as item()+ {
let $header-elements := map:merge(map{'Content-Type': if (matches(req:header("ACCEPT"), '[+/]json')) then 'application/problem+json' else 'application/problem+xml'}),
    $error-status := if ($problem/rfc7807:status castable as xs:integer) then xs:integer($problem/rfc7807:status) else 400
return (<rest:response>
    <http:response status="{$error-status}" message="{$_:codes_to_message($error-status)}">
        {_:map_to_header_elements($header-elements)}
    </http:response>
 </rest:response>,
 _:on_accept_to_json($problem)
)   
};

declare %private function _:map_to_header_elements($header-elements as map(xs:string, xs:string)) as element()* {
    map:for-each($header-elements, function($key, $value){
        <http:header name="{$key}" value="{$value}"/>
    })
};

declare %private function _:on_accept_to_json($problem as element(rfc7807:problem)) as item() {
  let $objects := string-join($problem//*[*[local-name() ne '_']]/local-name(), ' '),
      $arrays := string-join($problem//*[*[local-name() eq '_']]/local-name(), ' ')
  return
  if (matches(req:header("ACCEPT"), '[+/]json'))
  then json:serialize(<json type="object" objects="{$objects}" arrays="{$arrays}">{$problem/*}</json>, map {'format': 'direct'})
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
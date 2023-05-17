xquery version "3.0";
module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";

declare namespace wde = "https://www.oeaw.ac.at/acdh/tools/vle";

import module namespace jobs = "http://basex.org/modules/jobs";
import module namespace l = "http://basex.org/modules/admin";

declare variable $_:basePath := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:selfName := tokenize(static-base-uri(), '/')[last()];
declare variable $_:vleUtilSortKey := "vutlsk";

declare function _:eval($query as xs:string, $bindings as map(*)?, $jobName as xs:string) as item()* {
  _:eval($query, $bindings, $jobName, false())
};

declare function _:eval($query as xs:string, $bindings as map(*)?, $jobName as xs:string, $dontCheckQuery as xs:boolean) as item()* {
    let (: $log := l:write-log($query, 'INFO'), :)
        $j := _:start-eval-job($query, $bindings, $jobName, $dontCheckQuery, 0), $_ := jobs:wait($j)   
    return jobs:result($j)
};

declare %private function _:start-eval-job($query as xs:string, $bindings as map(*)?, $jobName as xs:string, $dontCheckQuery as xs:boolean, $subJobNumber as xs:integer) as xs:string {
    let $too-many-jobs := if (count(jobs:list()) >= xs:integer(db:system()//parallel)) then 
                          error(xs:QName('wde:too-many-parallel-requests'), 'Too many parallel requests! (>='||db:system()//parallel||')') else (),
        $query-is-sane := $dontCheckQuery or _:query-is-sane($query)
        (: , $log := l:write-log($jobName||'-'||$subJobNumber||'-'||jobs:current()||': '||$query, 'DEBUG') :)
        (: , $log_write := file:write(file:resolve-path($_:basePath||'/vleserver_'||$jobName||'-'||$subJobNumber||'.xq', file:base-dir()), $query) :)
        return jobs:eval($query, $bindings, map {
          'cache': true(),
          'id': 'vleserver:'||$jobName||'-'||$subJobNumber||'-'||jobs:current(),
          'base-uri': $_:basePath||'/vleserver_'||$jobName||'-'||$subJobNumber||'.xq'})
};

(: throws wde:dubious-query :)
declare %private function _:query-is-sane($query as xs:string) as xs:boolean {
   let $error-class := xs:QName('_:dubious-query'),
      $parsed-query := try {
        xquery:parse($query, map {'pass': true()})
      } catch * {error($error-class, ``[Query error:
      `{$query}` 
      `{$err:code}` `{$err:description}` `{$err:line-number}`/`{$err:column-number}`]``)},
      (: $log := l:write-log(serialize($parsed-query), 'DEBUG'), :)
      $contains-update := if ($parsed-query/@updating ne 'false') then error($error-class, 'Query is updating: '||$query) else (),
      $contains-xquer-eval := if (exists($parsed-query//XQueryEval) or exists($parsed-query//XQueryInvoke)) then error($error-class, 'Query contains xquery:eval: '||$query) else (),
      $contains-jobs-eval := if (exists($parsed-query//JobsEval) or exists($parsed-query//JobsInvoke)) then error($error-class, 'Query contains jobs:eval: '||$query) else (),
      $contains-http-request := if (exists($parsed-query//HttpSendRequest)) then error($error-class, 'Query contains http:send-request: '||$query) else ()
  return true()
};

declare function _:evals($queries as xs:string+, $bindings as map(*)?, $jobName as xs:string, $dontCheckQuery as xs:boolean) as item()* {
    (: WARNING: Clean up code is missing. If queries come in too fast (below 100 ms between each) or too many (more than 10 is not testet)
       batch-size may go down to 0 and/or the wde:too-many-parallel-requests error may show :)
    let $start := prof:current-ns(),
        $randMs := random:integer(100),
        $randSleep := prof:sleep($randMs),
        $batch-size := _:get-batch-size(),
        $batches := (0 to xs:integer(ceiling(count($queries) div $batch-size))),
        (: , $log := l:write-log('$randMs := '||$randMs||' $batch-size := '||$batch-size, 'DEBUG') :)
        $ret := for $batch-number in $batches
                let $js := subsequence($queries, $batch-number * $batch-size + 1, $batch-size)!_:start-eval-job(., $bindings, $jobName, $dontCheckQuery, xs:integer($batch-size * $batch-number + position()))
                  , $_ := $js!jobs:wait(.)
                (:, $status := jobs:list-details()[@id = $js]
                  , $log := $status!l:write-log('Job '||./@id||' duration '||seconds-from-duration(./@duration)*1000||' ms') :)
                return _:get-results-or-errors($js)
      , $runtime := ((prof:current-ns() - $start) idiv 10000) div 100
      , $log := if ($runtime > 100) then l:write-log('Batch execution of '||count($queries)||' jobs for '||$jobName||' took '||$runtime||' ms') else ()
      (: , $logMore := l:write-log(serialize($ret[. instance of node()]/self::_:error, map{'method': 'xml'})) :)
    return _:throw-on-error-in-returns($ret)
};

declare function _:get-batch-size() as xs:integer {
  xs:integer(floor((xs:integer(db:system()//parallel) - count(jobs:list())) * 1 div 3))
};

declare function _:get-results-or-errors($js as xs:string*) {
   $js!(try { jobs:result(.) }
        catch * {
                  <_:error>
                    <_:code>{$err:code}</_:code>
                    <_:code-namespace>{namespace-uri-from-QName($err:code)}</_:code-namespace>
                    <_:description>{$err:description}</_:description>
                    <_:value>{$err:value}</_:value>
                    <_:module>{$err:module}</_:module>
                    <_:line-number>{$err:line-number}</_:line-number>
                    <_:column-number>{$err:column-number}</_:column-number>
                    <_:additional>{$err:additional}</_:additional>
                  </_:error>
                })
};

declare function _:throw-on-error-in-returns($ret) {
if (exists($ret[. instance of node()]/self::_:error))
then ($ret[. instance of node()]/self::_:error)[1]!error(QName(./_:code-namespace, ./_:code),
          ($ret[. instance of node()]/self::_:error)[1]/_:description,
          string-join($ret[. instance of node()]/self::_:error/_:additional, '&#x0a;'))
else $ret  
};

declare function _:get-xml-file-or-default($fn as xs:string, $default as xs:string) as document-node() {
   _:get-xml-file-or-default($fn, $default, true())
};

(:~
 : Executes one query using a sequence of different bindings in a map
 : For example with seqenceKey := 'sequenceKey'
 : map { 'sequenceKey': (<a/>,<b/>)}
 :)
declare function _:evals($query as xs:string, $bindings as map(*)?, $sequenceKey as xs:string, $batch-size as xs:integer, $jobName as xs:string, $dontCheckQuery as xs:boolean) as item()* {
      (: WARNING: Clean up code is missing. If queries come in too fast (below 100 ms between each) or too many (more than 10 is not testet)
       batch-size may go down to 0 and/or the wde:too-many-parallel-requests error may show :)
    let $start := prof:current-ns(),
        $randMs := random:integer(100),
        $randSleep := prof:sleep($randMs),
        $batches := (0 to xs:integer(ceiling(count($bindings($sequenceKey)) div $batch-size)) - 1),
     (: $log := l:write-log('$randMs := '||$randMs||' $batch-size := '||$batch-size, 'DEBUG'), :)
        $ret := for $batch-number at $batch-pos in $batches
                let $batch-bindings := map:merge((map {$sequenceKey: subsequence($bindings($sequenceKey), $batch-number * $batch-size + 1, $batch-size)}, $bindings)),
                 (: $log := l:write-log(serialize($batch-bindings, map {'method': 'basex'}), 'DEBUG'), :)
                    $js := _:start-eval-job($query, $batch-bindings, $jobName, $dontCheckQuery, xs:integer($batch-size * $batch-number + $batch-pos))
                  , $_ := $js!jobs:wait(.)
                (:, $status := jobs:list-details()[@id = $js]
                  , $log := $status!l:write-log('Job '||./@id||' duration '||seconds-from-duration(./@duration)*1000||' ms') :)
                return _:get-results-or-errors($js)
      , $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
        $log := if ($runtime > 100) then l:write-log('Batch execution of '||count($bindings($sequenceKey))||' jobs for '||$jobName||' took '||$runtime||' ms') else ()
    return _:throw-on-error-in-returns($ret)
};

declare function _:get-xml-file-or-default($fn as xs:string, $default as xs:string, $fn-is-valid as xs:boolean) as document-node() {
  let $q := if ($fn-is-valid) then ``[if (doc-available("`{$fn}`")) then doc("`{$fn}`") else doc("`{$default}`")]`` else
            ``[doc("`{$default}`")]``,
      $jid := jobs:eval($q, (), map {'cache': true(), 'base-uri': $_:basePath||'/'}), $_ := jobs:wait($jid)
  return jobs:result($jid)    
};

(: result is not sorted, most probably document order applies :)
declare function _:dehydrate($nodes as node()*, $data-extractor-xquery as function(node()) as attribute()*?) as element(_:dryed)* {
  for $nodes_in_db in $nodes
  group by $db_name := _:db-name($nodes_in_db)
  let $pres := db:node-pre($nodes_in_db)
  return (# db:copynode false #) { <_:dryed db_name="{$db_name}" order="none" created="{current-dateTime()}">
  {for $n at $i in $nodes_in_db
    let $extracted-attrs := try {
      $data-extractor-xquery($n)
    } catch * {
      '  _error_: '||$err:description
    }
    return <_:d pre="{$pres[$i]}" db_name="{$db_name}">{$extracted-attrs}</_:d>
  }
  </_:dryed> }
};

(: db:name causes global read lock :)
declare function _:db-name($n as node()) as xs:string {
  replace($n/base-uri(), '^/([^/]+)/.*$', '$1')
};

declare function _:hydrate($dryed as element(_:d)+) as node()* {
  let $queries := for $d in $dryed
      let $db_name := $d/@db_name
      group by $db_name
      let $pre_seq := '('||string-join($d/@pre, ', ')||')',
          $sort_key_seq := '("'||string-join($d/@*[local-name() = $_:vleUtilSortKey]!
            (replace(., '"', '&amp;quot;', 'q') => replace('&amp;([^q])', '&amp;amp;$1')), '","')||'")'
      return ``[declare namespace  _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
    for $pre at $i in `{$pre_seq}`
    return <_:h db_name="`{$db_name}`" pre="{$pre}" `{$_:vleUtilSortKey}`="{`{$sort_key_seq}`[$i]}">{db:open-pre("`{$db_name}`", $pre)}</_:h>
  ]``
  return _:evals($queries, (), 'util:hydrate', false())
};

(: $filter_code is a XQuery function
   declare function filter($nodes as node()*) as node()* {()};
:)
declare function _:hydrate($dryed as element(_:d)+, $filter_code as xs:string) as node()* {
  let $queries := for $d in $dryed
      let $db_name := $d/@db_name
      group by $db_name
      let $pre_seq := '('||string-join($d/@pre, ',')||')',
          $sort_key_seq := '("'||string-join($d/@*[local-name() = $_:vleUtilSortKey]!
            (replace(., '"', '&amp;quot;', 'q') => replace('&amp;([^q])', '&amp;amp;$1')), '","')||'")',
          $assert-seqs-match := if (count($d/@pre) ne count($d/@*[local-name() = $_:vleUtilSortKey]!xs:string(.)))
            then error(xs:QName('_:seq_mismatch'), 'pre and sort key don''t match')
            else ()
      return ``[declare namespace  _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
    `{$filter_code}`
    for $pre at $i in `{$pre_seq}`
    return <_:h db_name="`{$db_name}`" pre="{$pre}" `{$_:vleUtilSortKey}`="{`{$sort_key_seq}`[$i]}">{local:filter(db:open-pre("`{$db_name}`",  $pre))}</_:h>
  ]``
  return _:evals($queries, (), 'util:hydrate-and-filter', false())
};

declare function _:get-public-scheme-and-hostname() as xs:string {
  let $forwarded-hostname := if (contains(request:header('X-Forwarded-Host'), ',')) 
                               then substring-before(request:header('X-Forwarded-Host'), ',')
                               else request:header('X-Forwarded-Host'),
      $urlScheme := if ((lower-case(request:header('X-Forwarded-Proto')) = 'https') or 
                        (lower-case(request:header('Front-End-Https')) = 'on')) then 'https' else 'http',
      $port := if ($urlScheme eq 'http' and request:port() ne 80) then ':'||request:port()
               else if ($urlScheme eq 'https' and not(request:port() eq 80 or request:port() eq 443)) then ':'||request:port()
               else ''
  return $urlScheme||'://'||($forwarded-hostname, request:hostname())[1]||$port
};

declare function _:get-base-uri-public() as xs:string {
  (: FIXME: this is to naive. Works for ProxyPass / to /exist/apps/cr-xq-mets/project
     but probably not for /x/y/z/ to /exist/apps/cr-xq-mets/project. Especially check the get module. :)
  let $xForwardBasedPath := (request:header('X-Forwarded-Request-Uri'), request:path())[1]
  return _:get-public-scheme-and-hostname()||$xForwardBasedPath
};

declare function _:basic-auth-decode($encoded-auth as xs:string) as xs:string {
  (: Mostly ASCII/ISO-8859-1. Can be UTF-8. See https://stackoverflow.com/a/7243567. 
     Postman encodes ISO-8859-1 :)
  let $base64 as xs:base64Binary := xs:base64Binary(replace($encoded-auth, '^Basic ', ''))
  return try {
    convert:binary-to-string($base64, 'UTF-8')
  } catch convert:string {
    convert:binary-to-string($base64, 'ISO-8859-1')
  }
};
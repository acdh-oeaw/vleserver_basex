xquery version "3.0";
module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";

import module namespace jobs = "http://basex.org/modules/jobs";
import module namespace l = "http://basex.org/modules/admin";

declare variable $_:basePath := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:selfName := tokenize(static-base-uri(), '/')[last()];

declare function _:eval($query as xs:string, $bindings as map(*)?, $jobName as xs:string) as item()* {
  _:eval($query, $bindings, $jobName, false())
};

declare function _:eval($query as xs:string, $bindings as map(*)?, $jobName as xs:string, $dontCheckQuery as xs:boolean) as item()* {
    let $j := _:start-eval-job($query, $bindings, $jobName, $dontCheckQuery, 0), $_ := jobs:wait($j)   
    return jobs:result($j)
};

declare %private function _:start-eval-job($query as xs:string, $bindings as map(*)?, $jobName as xs:string, $dontCheckQuery as xs:boolean, $subJobNumber as xs:integer) as xs:string {
    let $too-many-jobs := if (count(jobs:list()) >= xs:integer(db:system()//parallel)) then 
                          error(xs:QName('wde:too-many-parallel-requests'), 'Too many parallel requests!') else (),
        $query-is-sane := $dontCheckQuery or _:query-is-sane($query)
        (: , $log := l:write-log($query, 'DEBUG') :)
        return jobs:eval($query, $bindings, map {
          'cache': true(),
          'id': 'sru:'||$jobName||'-'||$subJobNumber||'-'||jobs:current(),
          'base-uri': $_:basePath||'/sru_'||$jobName||'-'||$subJobNumber||'.xq'})
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
        $batch-size := floor((xs:integer(db:system()//parallel) - count(jobs:list())) * 1 div 3),
        $batches := (0 to xs:integer(ceiling(count($queries) div $batch-size))),
        (: , $log := l:write-log('$randMs := '||$randMs||' $batch-size := '||$batch-size, 'DEBUG') :)
        $ret := for $batch-number in $batches
                let $js := subsequence($queries, $batch-number * $batch-size + 1, $batch-size)!_:start-eval-job(., $bindings, $jobName, $dontCheckQuery, xs:integer($batch-size * $batch-number + position()))
                  , $_ := $js!jobs:wait(.)
                  , $status := jobs:list-details()[@id = $js]
                (:, $log := $status!l:write-log('Job '||./@id||' duration '||seconds-from-duration(./@duration)*1000||' ms') :)
                return $js!jobs:result(.)
      , $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
        $log := if ($runtime > 100) then l:write-log('Batch execution of '||count($queries)||' jobs for '||$jobName||' took '||$runtime||' ms') else ()
    return $ret
};

declare function _:get-xml-file-or-default($fn as xs:string, $default as xs:string) as document-node() {
   _:get-xml-file-or-default($fn, $default, true())
};

declare function _:evals($query as xs:string, $bindings as map(*)?, $sequenceKey as xs:string, $jobName as xs:string, $dontCheckQuery as xs:boolean) as item()* {
      (: WARNING: Clean up code is missing. If queries come in too fast (below 100 ms between each) or too many (more than 10 is not testet)
       batch-size may go down to 0 and/or the wde:too-many-parallel-requests error may show :)
    let $start := prof:current-ns(),
        $randMs := random:integer(100),
        $randSleep := prof:sleep($randMs),
        $batch-size := floor((xs:integer(db:system()//parallel) - count(jobs:list())) * 1 div 3),
        $batches := (0 to xs:integer(ceiling(count($bindings($sequenceKey)) div $batch-size))),
        (: , $log := l:write-log('$randMs := '||$randMs||' $batch-size := '||$batch-size, 'DEBUG') :)
        $ret := for $batch-number in $batches
                let $js := _:start-eval-job($query, map:merge((map {$sequenceKey: subsequence($bindings($sequenceKey), $batch-number * $batch-size + 1, $batch-size)}, $bindings)), $jobName, $dontCheckQuery, xs:integer($batch-size * $batch-number + position()))
                  , $_ := $js!jobs:wait(.)
                  , $status := jobs:list-details()[@id = $js]
                (:, $log := $status!l:write-log('Job '||./@id||' duration '||seconds-from-duration(./@duration)*1000||' ms') :)
                return $js!jobs:result(.)
      , $runtime := ((prof:current-ns() - $start) idiv 10000) div 100,
        $log := if ($runtime > 100) then l:write-log('Batch execution of '||count($bindings($sequenceKey))||' jobs for '||$jobName||' took '||$runtime||' ms') else ()
    return $ret
};

declare function _:get-xml-file-or-default($fn as xs:string, $default as xs:string, $fn-is-valid as xs:boolean) as document-node() {
  let $q := if ($fn-is-valid) then ``[if (doc-available("`{$fn}`")) then doc("`{$fn}`") else doc("`{$default}`")]`` else
            ``[doc("`{$default}`")]``,
      $jid := jobs:eval($q, (), map {'cache': true(), 'base-uri': $_:basePath||'/'}), $_ := jobs:wait($jid)
  return jobs:result($jid)    
};

declare function _:dehydrate($nodes as node()*) as element(_:dryed)* {
  for $nodes_per_db in $nodes
  group by $db_name := db:name($nodes_per_db)
  return <_:dryed db_name="{$db_name}"
           pres="{string-join(db:node-pre($nodes_per_db), ' ')}"
  />
};

declare function _:hydrate($dryed as element(_:dryed)) as node()* {
  let $queries := $dryed!``[tokenize("`{data(./@pres)}`")!db:open-pre("`{./@db_name}`",  xs:integer(.))]``
  return _:evals($queries, (), 'util:hydrate', false())
};


(: $filter_code is a XQuery function
   declare function filter($nodes as node()*) as node()* {()};
:)
declare function _:hydrate($dryed as element(_:dryed), $filter_code as xs:string) as node()* {
  let $queries := $dryed!``[`{$filter_code}`
    let $nodes := tokenize("`{data(./@pres)}`")!db:open-pre("`{./@db_name}`",  xs:integer(.))
    return local:filter($nodes)
  ]``
  return _:evals($queries, (), 'util:hydrate', false())
};
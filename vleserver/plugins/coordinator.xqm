xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare variable $_:enable_trace := false();

(: $data := map {'current': map {'$id': map {'entry': <entry/>,
                                            'db_name': $db_name}},
                                 '$id': ...}
                }
:)

declare function _:after_created($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $changingUser as xs:string) as empty-sequence() {
for $data_per_db in map:for-each($data?current, function ($id, $data) {map{$id: $data}})
group by $db_name := $data_per_db?*?db_name 
return
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
import module namespace cache-update = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update' at 'plugins/cache-update.xqm';
declare variable $data as map(xs:string, map(xs:string, map(xs:string, item()?))) external;
example:after_created($data, "`{$dict}`", "`{$db_name}`", "`{$changingUser}`"),
cache-update:after_created($data, "`{$dict}`", "`{$db_name}`", "`{$changingUser}`")]``, map {
            'data': map {'current': map:merge($data_per_db) }
          }, 'after_created', true())
};

(: $data := map {'current': map {'$id': map {'entry': <entry/>,
                                            'db_name': $db_name}},
                                 '$id': ...},
                 'before': map {'$id': map {'entry': <entry/>,
                                            'db_name': $db_name}},
                                 '$id': ...}
                }
:)

declare function _:after_updated($data, $dict as xs:string, $changingUser as xs:string) as map(*) {
let $ret := for $data_per_db in map:for-each($data?current, function ($id, $data) {map{$id:$data}})
group by $db_name := $data_per_db?*?db_name
let $currentData := map:merge($data_per_db),
    $beforeData := map:merge(map:for-each($data?before, function($id, $data) {if ($id = map:keys($currentData)) then map {$id: $data} else ()}))
  (: , $_ := _:write-log('after_update$currentData'||serialize($currentData, map{"method": "basex"})),
    $_ := _:write-log('after_update$beforeData'||serialize($beforeData, map{"method": "basex"})) :)
return
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
import module namespace cache-update = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update' at 'plugins/cache-update.xqm';
declare variable $data external;
let $example-after_updated := prof:track(example:after_updated($data, "`{$dict}`", "`{$db_name}`", "`{$changingUser}`")),
    $cache-update-after_updated := prof:track(cache-update:after_updated($data, "`{$dict}`", "`{$db_name}`", "`{$changingUser}`"))
return map {
  'value': ($example-after_updated?value, $cache-update-after_updated?value),
  'time': map {
    'example-after_updated': $example-after_updated?time,
    'cache-update-after_updated': $cache-update-after_updated?time
  },
  'memory': map {}
 }]``, map {
            'data':  map {'current': $currentData,
                          'before': $beforeData }
          }, 'after_updated', true())
return map {
  'value': $ret?value,
  'time': map {
    '@coordinator@after_updated:example-after_updated': sum($ret?time?example-after_updated),
    '@coordinator@after_updated:cache-update-after_updated': sum($ret?time?cache-update-after_updated)
  },
  'memory': map {}
}
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
import module namespace cache-update = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update' at 'plugins/cache-update.xqm';
example:after_deleted("`{$dict}`", "`{$id}`", "`{$db_name}`", "`{$changingUser}`"),
cache-update:after_deleted("`{$dict}`", "`{$id}`", "`{$db_name}`", "`{$changingUser}`")]``, (), 'after_deleted', true())  
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};

declare %private function _:write-log($message as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, "TRACE") else ()
};
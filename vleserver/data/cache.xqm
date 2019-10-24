xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache';
import module namespace data-access = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at 'access.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at "profile.xqm";

declare variable $_:basePath := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:sortBatchSize := 1500000;
declare variable $_:optimizeOptions := "map {'attrindex': true()}";

declare function _:cache-all-entries($dict as xs:string) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $data-extractor-xquery := profile:get-lemma-xquery($profile),
    $recreate-cache := (util:eval(``[try {
        db:drop("`{$dict||'__cache'}`")
      } catch db:open {()}]``, (), 'drop-cache', true()),
      util:eval(``[db:create("`{$dict||'__cache'}`")]``, (), 'drop-cache', true())),
    $cache-all-entries-scripts := for $dbs at $p in $dbs
    let $key := floor($p div 10)
    group by $key
    return 
      if (exists($dbs[not(ends-with(., '__prof'))])) then ``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util";
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            declare function local:extractor($node as node()) as attribute()* {
              ($node/@ID, $node/@xml:id,
               attribute {$util:vleUtilSortKey} {string-join(`{$data-extractor-xquery}`, ', ')})
            };
            let $dryeds as element(util:dryed)+ := (`{string-join(for $db in $dbs[not(ends-with(., '__prof'))] return ``[
            data-access:do-get-index-data(collection("`{$db}`"), (), (), local:extractor#1, 0)]``, ',')
            }`)
            return jobs:eval(``[declare namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util";
         declare variable $dryeds as element(util:dryed)+ external;
         $dryeds!db:replace("`{$dict||'__cache'}`", ./@db_name||'_cache.xml', .)]``||']``'||
         ``[, map{'dryeds': $dryeds}, map {
          'cache': false(),
          'id': 'vleserver:cache-all-entrie-write-script`{$key}`-'||jobs:current(),
          'base-uri': '`{$_:basePath}`/vleserver_cache-all-entries-write-script`{$key}`.xq'})]``
       else (),
    $write-jobs := if (exists($cache-all-entries-scripts)) then util:evals($cache-all-entries-scripts, (),
    'cache-all-entries-script', true()) else (),
    $_ := $write-jobs!jobs:wait(.),
    $optimize-xquery := "db:optimize('"||$dict||'__cache'||"', true(),"||$_:optimizeOptions||")",
    $sorted := (
    util:eval(_:sort-cache-xquery($dict, 'ascending'), (), 'sort-cache-write-order-ascending', true()),
    util:eval(_:sort-cache-xquery($dict, 'descending'), (), 'sort-cache-write-order-descending', true()))
    return util:eval($optimize-xquery, (), 'optimize-cache', true())
};

(: db:copynode false is essential here. Can exhaust the memory otherwise. :)
declare function _:sort-cache-xquery($dict as xs:string, $order as xs:string) {
``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
(# db:copynode false #) {
let $sorted := for $d in collection('`{$dict}`__cache')//*[@order="none"]/_:d
  order by $d/@`{$util:vleUtilSortKey}` `{$order}`
  return $d
return db:replace("`{$dict||'__cache'}`", '`{$order}`_cache.xml', <_:dryed order="`{$order}`">{$sorted}</_:dryed>)}]``
};

declare function _:refresh-cache-db($dict as xs:string, $db_name as xs:string) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $data-extractor-xquery := profile:get-lemma-xquery($profile),
    $query := ``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at "util.xqm";
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            declare function local:extractor($node as node()) as attribute()* {
              ($node/@ID, $node/@xml:id,
               attribute {$util:vleUtilSortKey} {string-join(`{$data-extractor-xquery}`, ', ')})
            };
            let $dryed as element(util:dryed) := data-access:do-get-index-data(collection("`{$db_name}`"), (), (), local:extractor#1, 0)
            return util:eval(``[declare namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util";
         declare variable $dryed as element(util:dryed) external;
         db:replace("`{$dict||'__cache'}`", $dryed/@db_name||'_cache.xml', $dryed)]``||']``'||
         ``[, map{'dryed': $dryed}, "refresh-cache-db-`{$db_name}`", true())]``,         
         $optimize-xquery := "db:optimize('"||$dict||'__cache'||"', true(),"||$_:optimizeOptions||")"
   return (util:eval(_:sort-cache-xquery($dict, 'ascending'), (), 'sort-cache-write-order-ascending', true()),
    util:eval(_:sort-cache-xquery($dict, 'descending'), (), 'sort-cache-write-order-descending', true()),
    util:eval($optimize-xquery, (), 'optimize-cache', true()))
};
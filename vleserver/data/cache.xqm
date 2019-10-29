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
            `{profile:generate-local-extractor-function($profile)}`
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
    $sorted := _:sort-and-optimize($dict, $profile)
    return $sorted
};

declare function _:sort-and-optimize($dict as xs:string, $profile as document-node()) {
let $alt-lemma-xqueries := profile:get-alt-lemma-xqueries($profile),
    $optimize-xquery := "db:optimize('"||$dict||'__cache'||"', true(),"||$_:optimizeOptions||")"
return (util:eval(_:sort-cache-xquery($dict, 'ascending', ()), (), 'sort-cache-write-order-ascending', true()),
    util:eval(_:sort-cache-xquery($dict, 'descending', ()), (), 'sort-cache-write-order-descending', true()),
    for $label in map:keys($alt-lemma-xqueries)
    return (util:eval(_:sort-cache-xquery($dict, 'ascending', $label), (), 'sort-cache-write-'||$label||'-order-ascending', true()),
    util:eval(_:sort-cache-xquery($dict, 'descending', $label), (), 'sort-cache-write-'||$label||'-order-descending', true())),
    util:eval($optimize-xquery, (), 'optimize-cache', true()))
};

(: db:copynode false is essential here. Can exhaust the memory otherwise. :)
declare function _:sort-cache-xquery($dict as xs:string, $order as xs:string, $alt-label as xs:string?) {
let $alt-label-postfix := if (exists($alt-label)) then '-'||$alt-label else '',
    $alt-label-attribute := if (exists($alt-label)) then ``[ label="`{$alt-label}`"]`` else ""
return ``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
(# db:copynode false #) {
let $sorted := for $d in collection('`{$dict}`__cache')//*[@order="none"]/_:d
  order by $d/@`{$util:vleUtilSortKey||$alt-label-postfix}` `{$order}`
  return $d
return db:replace("`{$dict||'__cache'}`", '`{$order||$alt-label-postfix}`_cache.xml', <_:dryed order="`{$order}`"`{$alt-label-attribute}`>{$sorted}</_:dryed>)}]``
};

declare function _:refresh-cache-db($dict as xs:string, $db_name as xs:string) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $query := ``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at "util.xqm";
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            `{profile:generate-local-extractor-function($profile)}`
            let $dryed as element(util:dryed) := data-access:do-get-index-data(collection("`{$db_name}`"), (), (), local:extractor#1, 0)
            return util:eval(``[declare namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util";
         declare variable $dryed as element(util:dryed) external;
         db:replace("`{$dict||'__cache'}`", $dryed/@db_name||'_cache.xml', $dryed)]``||']``'||
         ``[, map{'dryed': $dryed}, "refresh-cache-db-`{$db_name}`", true())]``,         
         $optimize-xquery := "db:optimize('"||$dict||'__cache'||"', true(),"||$_:optimizeOptions||")"
   return _:sort-and-optimize($dict, $profile)
};

declare function _:get-all-entries($dict as xs:string, $from as xs:integer, $num as xs:integer, $sort as xs:string?, $label as xs:string?) as element(util:d)* {
let $sort := switch($sort)
        case "asc" return "ascending"
        case "desc" return "descending"
        case "none" return "none"
        default return "ascending",
    $label := if (exists($label)) then "and @label = '"||$label||"'" else "and not(@label)"
return util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  subsequence(collection("`{$dict}`__cache")//_:dryed[@order='`{$sort}`' `{$label}`]/_:d, `{$from}`, `{$num}`)]``, (), 'count-all-entries')
};

declare function _:count-all-entries($dict as xs:string) as xs:integer {
  util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  count(collection("`{$dict}`__cache")//_:dryed[@order='none']/_:d)]``, (), 'count-all-entries')
};
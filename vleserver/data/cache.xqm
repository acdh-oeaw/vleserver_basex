xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache';
import module namespace data-access = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at 'access.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at "profile.xqm";

declare variable $_:basePath := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:sortMaxSize := 15000;
declare variable $_:optimizeOptions := "map {'updindex': true(), 'attrindex': true(), 'attrinclude': 'Q{http://www.w3.org/XML/1998/namespace}id, ID, order, label, db_name'}";

declare function _:cache-all-entries($dict as xs:string) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $alt-labels := ("", map:keys(profile:get-alt-lemma-xqueries($profile))),
    $alt-label-postfixes := $alt-labels!(if (. ne "") then '-'||. else ''),
    $data-extractor-xquery := profile:get-lemma-xquery($profile),
    $recreate-cache := (util:eval(``[db:create("`{$dict||'__cache'}`")]``, (), 'create-empty-cache', true())),
    $cache-all-entries-scripts := for $dbs at $p in $dbs
    let $key := floor($p div 10)
    group by $key
    return (
      if (exists($dbs)) then ``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            `{profile:generate-local-extractor-function($profile)}`
            let $dryeds as element(util:dryed)+ := (`{string-join(
            (for $db in $dbs[ends-with(., '__prof')] return ``[
            util:dehydrate(collection('`{$db}`')//profile, function($n){($n/@xml:id, `{
              string-join(
              for $alt-label-postfix in $alt-label-postfixes
              return``[attribute {'`{$util:vleUtilSortKey||$alt-label-postfix}`'} {'  profile'}]``, ',')}`)})
            ]``,
            for $db in $dbs[not(ends-with(., '__prof'))] return ``[
            data-access:do-get-index-data(collection("`{$db}`"), (), (), local:extractor#1, 0)]``), ',')
            }`)
            return jobs:eval(``[declare namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util";
         declare variable $dryeds as element(util:dryed)+ external;
         $dryeds!db:replace("`{$dict||'__cache'}`", ./@db_name||'_cache.xml', .)]``||']``'||
         ``[, map{'dryeds': $dryeds}, map {
          'cache': false(),
          'id': 'vleserver:cache-all-entrie-write-script`{$key}`-'||jobs:current(),
          'base-uri': '`{$_:basePath}`/vleserver_cache-all-entries-write-script`{$key}`.xq'})]``
       else ()),
    $write-jobs := if (exists($cache-all-entries-scripts)) then util:evals($cache-all-entries-scripts, (),
    'cache-all-entries-script', true()) else (),
    $_ := $write-jobs!jobs:wait(.),
    $optimze := util:eval(``[db:optimize("`{$dict}`__cache", true(), `{$_:optimizeOptions}`)]``, (), 'optimize-cache', true()),
    $sorted := _:sort($dict)
    return $sorted
};

declare function _:sort($dict as xs:string) {
  util:eval(_:sort-cache-xquery($dict), (), 'sort-cache-write', true())
};

declare function _:sort-cache-xquery($dict as xs:string) {
let $profile := profile:get($dict),
    $alt-labels := ("", map:keys(profile:get-alt-lemma-xqueries($profile))),
    $alt-label-postfixes := $alt-labels!(if (. ne "") then '-'||. else ''),
    $alt-label-attributes := $alt-labels!(if (. ne "") then ``[ label="`{.}`"]`` else "")
return ``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
`{for $alt-label-postfix in $alt-label-postfixes
return ``[
let $sorted-ascending`{$alt-label-postfix}` := for $key in collection('`{$dict}`__cache')//*[@order="none"]/_:d/@`{$util:vleUtilSortKey||$alt-label-postfix}`
  order by data($key) ascending
  return $key]``}`
return (`{string-join(for $alt-label-postfix at $i in $alt-label-postfixes
return ``[db:replace("`{$dict||'__cache'}`", 'ascending`{$alt-label-postfix}`_cache.xml', <_:dryed order="ascending"`{$alt-label-attributes[$i]}` ids="{string-join(subsequence($sorted-ascending`{$alt-label-postfix}`, 1, `{$_:sortMaxSize}`)/../(@ID, @xml:id), ' ')}"/>),
db:replace("`{$dict||'__cache'}`", 'descending`{$alt-label-postfix}`_cache.xml', <_:dryed order="descending"`{$alt-label-attributes[$i]}` ids="{string-join(subsequence(reverse($sorted-ascending`{$alt-label-postfix}`), 1, `{$_:sortMaxSize}`)/../(@ID, @xml:id), ' ')}"/>)]``, ',&#x0a;')}`)]``
};

(: this is slightly slower than the above. There seems to be no gain in doing a fork-join here. :)
declare function _:sort-cache-xquery2($dict as xs:string) {
let $profile := profile:get($dict),
    $alt-labels := ("", map:keys(profile:get-alt-lemma-xqueries($profile))),
    $alt-label-postfixes := $alt-labels!(if (. ne "") then '-'||. else ''),
    $alt-label-attributes := $alt-labels!(if (. ne "") then ``[ label="`{.}`"]`` else "")
return ``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
import module namespace cache = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at 'data/cache.xqm';
let $ids := map:merge(xquery:fork-join((`{string-join(for $alt-label-postfix in $alt-label-postfixes
return ``[
 cache:order-by-key-ids-asc("sorted-ascending`{$alt-label-postfix}`", collection('`{$dict}`__cache')//@`{$util:vleUtilSortKey||$alt-label-postfix}`)]``, ',')}`)))
return (`{string-join(for $alt-label-postfix at $i in $alt-label-postfixes
return ``[db:replace("`{$dict||'__cache'}`", '`ascending`{$alt-label-postfix}`_cache.xml', <_:dryed order="ascending"`{$alt-label-attributes[$i]}` ids="{string-join(subsequence($ids('sorted-ascending`{$alt-label-postfix}`'), 1, `{$_:sortMaxSize}`)/../(@ID, @xml:id), ' ')}"/>),
db:replace("`{$dict||'__cache'}`", 'descending`{$alt-label-postfix}`_cache.xml', <_:dryed order="descending"`{$alt-label-attributes[$i]}` ids="{string-join(subsequence(reverse($ids('sorted-ascending`{$alt-label-postfix}`')), 1, `{$_:sortMaxSize}`)/../(@ID, @xml:id), ' ')}"/>)
]``, ',&#x0a;')}`)]``
};

declare function _:order-by-key-ids-asc($name as xs:string, $key-attrs as attribute()*) as function() as map(xs:string, attribute()*) {
  function() as map(xs:string, attribute()*) { map {$name:
      for $key-attr in $key-attrs
        order by xs:string($key-attr) ascending
        return $key-attr}
    }
};

declare function _:refresh-cache-db($dict as xs:string, $db_name as xs:string, $sort-again as xs:boolean) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $query := (util:eval(``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at "util.xqm";
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            `{profile:generate-local-extractor-function($profile)}`
            let $dryed as element(util:dryed) := data-access:do-get-index-data(collection("`{$db_name}`"), (), (), local:extractor#1, 0)
            return db:replace("`{$dict||'__cache'}`", $dryed/@db_name||'_cache.xml', $dryed)]``, (), "refresh-cache-db-"||$db_name, true()), if ($sort-again) then _:sort($dict) else ())
   return $query
};

declare function _:get-all-entries($dict as xs:string, $from as xs:integer, $num as xs:integer, $sort as xs:string?, $label as xs:string?, $total_items_expected as xs:integer) as element(util:d)* {
let $label-pred-part := if ($sort = 'none') then '' else _:label-to-pred-part($label),
    $alt-label-postfix := if ($label ne "") then '-'||$label else ''
return util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  declare namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache";
  declare variable $total_items_expected as xs:integer external;
  try {
  let $all := collection("`{$dict}`__cache")//_:dryed[@order='`{_:sort-to-long-str($sort)}`' `{$label-pred-part}`]/(_:d, tokenize(@ids)),
      $any_found := if (count($all) > 0) then true()
      else error(xs:QName('cache:missing'),
           'expected any result from cache got 0'),
      $all_found := if (count($all) = $total_items_expected or count($all) = `{$_:sortMaxSize}`) then true()
      else error(xs:QName('cache:stale'),
           'expected '||$total_items_expected||' results got '||count($all))
  return if ($all instance of xs:string*)
         then `{if ($sort = 'none') then '()' else
           ``[if (subsequence($all, `{$from}`, `{$num}`) instance of empty-sequence())
           then subsequence(for $key in collection('`{$dict}`__cache')//@`{$util:vleUtilSortKey||$alt-label-postfix}`
             order by data($key) `{_:sort-to-long-str($sort)}`
             return $key, `{$from}`, `{$num}`)/..
           else db:attribute("`{$dict}`__cache", subsequence($all, `{$from}`, `{$num}`))[. instance of attribute(ID) or . instance of attribute(xml:id)]/..]``}`
         else subsequence($all, `{$from}`, `{$num}`)
  } catch db:* | err:FODC0002 {
    error(xs:QName('cache:missing'),
           'expected any result from cache got 0')
  }]``,
  map {'total_items_expected': $total_items_expected}, 'cache-get-all-entries')
};

declare %private function _:sort-to-long-str($short as xs:string?) as xs:string {
switch($short)
  case "asc" return "ascending"
  case "desc" return "descending"
  case "none" return "none"
  default return "ascending"
};

declare %private function _:label-to-pred-part($label as xs:string?) as xs:string {
  if (exists($label)) then "and @label = '"||$label||"'" else "and not(@label)"
};

declare function _:count-all-entries($dict as xs:string) as xs:integer {
  util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  count(collection("`{$dict}`__cache")//_:dryed[@order='none']/_:d)]``, (), 'count-all-entries')
};

declare function _:get-entries-by-ids($dict as xs:string, $ids as xs:string+, $from as xs:integer, $num as xs:integer, $sort as xs:string?, $label as xs:string?, $total_items_expected as xs:integer) as element(util:d)* {
let $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $alt-label-postfix :=if ($label ne "") then '-'||$label else ''
return util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  declare namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache";
  declare variable $total_items_expected as xs:integer external;
  try {
  let $all := db:attribute("`{$dict}`__cache", `{$ids_seq}`)[local-name() = ('ID', 'id') and ancestor::_:dryed[@order='none']]/..,
      $any_found := if (count($all) > 0) then true()
      else error(xs:QName('cache:missing'),
           'expected any result from cache got 0'),
      $all_found := if (count($all) = $total_items_expected) then true()
      else error(xs:QName('cache:stale'),
           'expected '||$total_items_expected||' results got '||count($all))
      `{if ($sort = 'none') then () else
      ``[, $all := for $d in $all
        order by $d/@`{$util:vleUtilSortKey||$alt-label-postfix}` `{_:sort-to-long-str($sort)}`
        return $d]``}`
  return subsequence($all, `{$from}`, `{$num}`)
  } catch db:* | err:FODC0002 {
    error(xs:QName('cache:missing'),
           'expected any result from cache got 0')
  }]``,
  map {'total_items_expected': $total_items_expected}, 'cache-get-entries-by-ids')
};

declare function _:get-entries-by-id-starting-with($dict as xs:string, $id_start as xs:string, $from as xs:integer, $num as xs:integer, $sort as xs:string?, $label as xs:string?, $total_items_expected as xs:integer) as element(util:d)* {
let $alt-label-postfix :=if ($label ne "") then '-'||$label else ''
return util:eval(``[declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util";
  declare namespace cache = "https://www.oeaw.ac.at/acdh/tools/vle/data/cache";
  declare variable $total_items_expected as xs:integer external;
  try {
  let $values := index:attributes("`{$dict}`__cache", "`{$id_start}`")/text(),
      $all := db:attribute("`{$dict}`__cache", $values)[local-name() = ('ID', 'id') and ancestor::_:dryed[@order='none']]/..,
      $any_found := if (count($all) > 0) then true()
      else error(xs:QName('cache:missing'),
           'expected any result from cache got 0'),
      $all_found := if (count($all) = $total_items_expected) then true()
      else error(xs:QName('cache:stale'),
           'expected '||$total_items_expected||' results got '||count($all))
      `{if ($sort = 'none') then () else
      ``[, $all := for $d in $all
        order by $d/@`{$util:vleUtilSortKey||$alt-label-postfix}` `{_:sort-to-long-str($sort)}`
        return $d]``}`
  return subsequence($all, `{$from}`, `{$num}`)
  } catch db:* | err:FODC0002 {
    error(xs:QName('cache:missing'),
           'expected any result from cache got 0')
  }]``,
  map {'total_items_expected': $total_items_expected}, 'cache-get-entries-by-id-starting-with')
};
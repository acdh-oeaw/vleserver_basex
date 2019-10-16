xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache';
import module namespace data-access = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at 'access.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at "profile.xqm";

declare function _:cache-all-entries($dict as xs:string) {
let $dbs:= data-access:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $data-extractor-xquery := profile:get-lemma-xquery($profile),
    $cache-all-entries-scripts := for $dbs at $p in $dbs
    let $key := floor($p div 10)
    group by $key
    return 
      <_>{(<get>{if (exists($dbs[not(ends-with(., '__prof'))])) then ``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            declare function local:extractor($node as node()) as xs:string* {
              `{$data-extractor-xquery}`
            };
            let $dryeds := (`{string-join(for $db in $dbs[not(ends-with(., '__prof'))] return ``[
            data-access:do-get-index-data(collection("`{$db}`"), (), (), local:extractor#1)]``, ',')
            }`)
            return $dryeds]``
       else ()}</get>,
       <store>{``[declare variable $dryeds external;
         $dryeds!db:replace("`{$dict||'__cache'}`", ./@db_name||'_cache.xml', .)]``}</store>
     )}</_>,
    $_ := if (exists($cache-all-entries-scripts)) then $cache-all-entries-scripts (: util:evals($get-all-entries-scripts, (),
    'get-cache-entries-script', true()) else ():)
return $_
};
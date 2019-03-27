xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mds = "http://www.loc.gov/mods/v3";

declare variable $_:enable_trace := false();

declare function _:get-profile($dict_name as xs:string) as document-node() {
  util:eval(``[collection("`{$dict_name}`__prof")]``, (), 'get-profile')
};

declare %private function _:get-list-of-data-dbs-from-profile($profile as document-node()) as xs:string* {
  let $db-regExp := data($profile/profile/tableName/@find-dbs),
      $dbs := if (exists($db-regExp)) then
        util:eval(``[db:list()[matches(., "`{$db-regExp}`")]]``, (), 'get-list-of-data-dbs')
        else $profile/profile/tableName/text()
  return $dbs
};

declare %private function _:get-list-of-data-dbs($dict as xs:string) as xs:string* {
  let $log := _:write-log('vleserver:get-list-of-data-dbs $dict := '||$dict, 'DEBUG'),
      $ret := ($dict||'__prof', _:get-list-of-data-dbs-from-profile(_:get-profile($dict)), _:get-skel-if-exists($dict))
    , $logRet := _:write-log('vleserver:get-list-of-data-dbs return '||string-join($ret, '; '), 'DEBUG')
  return $ret
};

declare %private function _:get-skel-if-exists($dict as xs:string) as xs:string? {
  util:eval(``[db:list()[. = "`{$dict}`__skel"]]``, (), 'get-ske-if-exists')
};

declare function _:get-entry-by-id($dict_name as xs:string, $id as xs:string) {
  let $dict_name := _:get-real-dict($dict_name, $id)
  return util:eval(``[collection("`{$dict_name}`")//*[@xml:id = "`{$id}`"]]``, (), 'getDictDictNameEntry')  
};

declare %private function _:get-real-dict($dict as xs:string, $id as xs:string) as xs:string {
let $dicts := _:get-list-of-data-dbs($dict),
    $get-db-for-id-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) 
      then ``[if (collection("`{$dict}`")//profile[@xml:id = "`{$id}`"]) then "`{$dict}`" else ()]``
      else ``[
            import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare variable $id external;
            let $orig := _:do-get-index-data(collection("`{$dict}`"), $id, ())
            return if ($orig) then "`{$dict}`" else ()
            ]``,
    $found-in-parts := if (exists($get-db-for-id-scripts)) then util:evals($get-db-for-id-scripts, map {
              'id': $id
            }, 'get-db-for-id-script', true()) else ()
return $found-in-parts
};

declare function _:get-all-entries($dict as xs:string) {
let $dicts := _:get-list-of-data-dbs($dict),
    $get-all-entries-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[collection("`{$dict}`")//profile]``
      else ``[
            import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            _:do-get-index-data(collection("`{$dict}`"), (), ())
            ]``,
    $found-in-parts := if (exists($get-all-entries-scripts)) then util:evals($get-all-entries-scripts, (),    
    'get-all-entries-script', true()) else ()
return $found-in-parts
};

declare function _:do-get-index-data($c as document-node()*, $id as xs:string?, $dt as xs:string?) {
  let $log := _:write-log('do-get-index-data base-uri($c) '||string-join($c!base-uri(.), '; ') ||' $id := '||$id, 'DEBUG'),
      $all-entries := ($c//tei:cit[@type = 'example'], 
                       $c//tei:teiHeader,
                       $c//tei:TEI,
                       $c//tei:form[@type = 'lemma'],
                       $c//mds:mods,
                       $c//tei:entry,
                       $c//tei:entryFree),
      $results := $all-entries[(if (exists($id)) then @xml:id = $id else true()) and (if (exists($dt)) then @dt = $dt else true())]
    , $retLog := _:write-log('do-get-index-data return '||string-join($results!local-name(.), '; '), 'DEBUG')
  return if (count($results) > 25) then util:dehydrate($results) else $results
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
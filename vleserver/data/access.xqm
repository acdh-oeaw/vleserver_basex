xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'elementTypes.xqm';
import module namespace chg = "https://www.oeaw.ac.at/acdh/tools/vle/data/changes" at 'changes.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at "profile.xqm";
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mds = "http://www.loc.gov/mods/v3";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace rfc-7807 = "urn:ietf:rfc:7807";

declare variable $_:basePath as xs:string := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:selfName as xs:string := tokenize(static-base-uri(), '/')[last()];
declare variable $_:enable_trace := false();
declare variable $_:max-direct-xml := 25;
declare variable $_:default_index_options := map{'textindex': true(), 
                                                 'attrindex': true(),
                                                 'ftindex': true(), 'casesens': false(), 'diacritics': false(), 'language': 'en',
                                                 'maxlen':192, 'maxcats':1000,'splitsize': 20};

declare function _:get-list-of-data-dbs($dict as xs:string) as xs:string* {
  let (: $log := _:write-log('acc:get-list-of-data-dbs $dict := '||$dict, 'DEBUG'), :)
      $ret := ($dict||'__prof', profile:get-list-of-data-dbs(profile:get($dict)), _:get-skel-if-exists($dict))
      (: , $logRet := _:write-log('acc:get-list-of-data-dbs return '||string-join($ret, '; '), 'DEBUG') :)
  return $ret
};

declare %private function _:get-skel-if-exists($dict as xs:string) as xs:string? {
  util:eval(``[db:list()[. = "`{$dict}`__skel"]]``, (), 'get-ske-if-exists')
};

declare function _:get-entry-by-id($dict_name as xs:string, $id as xs:string) as element() {
  let $dict_name := _:get-real-dicts($dict_name, $id)
  return util:eval(``[collection("`{$dict_name}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]]``, (), 'getDictDictNameEntry')  
};

declare function _:get-real-dicts($dict as xs:string, $ids as xs:string+) as xs:string+ {
let $dicts := _:get-list-of-data-dbs($dict),
    $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $get-db-for-id-script := '('||string-join(for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[
      if (collection("`{$dict}`")//profile[@xml:id = `{$ids_seq}` or @ID = `{$ids_seq}`])
      then "`{$dict}`"
      else ()]``
      else ``[if (db:attribute("`{$dict}`", `{$ids_seq}`)) then "`{$dict}`" else ()]``
    , ',&#x0a;')||')',
    $found-in-parts := if ($get-db-for-id-script ne '()') then util:eval($get-db-for-id-script,
            (), 'get-real-dicts', true()) else ()
return if (exists($found-in-parts)) then $found-in-parts
       else error(xs:QName('response-codes:_404'),
                           'Not found',
                           'IDs '||$ids_seq||' not found')
};

declare function _:get-real-dicts-id-starting-with($dict as xs:string, $id_start as xs:string) as xs:string+ {
  let $dicts := _:get-list-of-data-dbs($dict),
      $get-db-for-id-script := '('||string-join(for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[
      if (collection("`{$dict}`")//profile[starts-with(@xml:id, "`{$id_start}`") or starts-with(@ID, "`{$id_start}`")])
      then "`{$dict}`"
      else ()]``
      else ``[if (index:attributes("`{$dict}`", "`{$id_start}`")) then "`{$dict}`" else ()]``
    , ',&#x0a;')||')',
    $found-in-parts := if ($get-db-for-id-script ne "") then util:eval($get-db-for-id-script,
            (), 'get-real-dicts-id-starting-with', true()) else ()
return if (exists($found-in-parts)) then $found-in-parts
       else error(xs:QName('response-codes:_404'),
                           'Not found',
                           'IDs starting with '||$id_start||' not found')
};

(: this may throw FODC0002 if $dict||'__prof' does not exist :)
declare function _:get-all-entries($dict as xs:string) {
let $dicts := _:get-list-of-data-dbs($dict),
    $profile := profile:get($dict),
    $altLabels := map:keys(profile:get-alt-lemma-xqueries($profile)),
    $get-all-entries-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) then _:get-profile-with-sort-xquery($dict, $altLabels)
      else ``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
            `{profile:generate-local-extractor-function($profile)}`
            _:do-get-index-data(collection("`{$dict}`"), (), (), local:extractor#1)
            ]``,
    (: $log-script1 := _:write-log($get-all-entries-scripts[1], 'INFO'),    
    $log-scriptn := _:write-log($get-all-entries-scripts[2], 'INFO'), :)
    $found-in-parts := if (exists($get-all-entries-scripts))
      then util:evals($get-all-entries-scripts, (),
        'get-all-entries-script', true()) else ()
return $found-in-parts
};

declare function _:count-all-entries($dict as xs:string) as xs:integer {
let $xqueries := _:get-list-of-data-dbs($dict)!
(if (ends-with(., '__prof')) then "1"
 else ``[import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
  count(types:get_all_entries(collection("`{.}`")))]``)
return sum(util:evals($xqueries, (), 'count-all-entries', true()))  
};

declare function _:get-profile-with-sort-xquery($db_name as xs:string, $altLabels as xs:string*) as xs:string {
let $labels := ('', $altLabels!('-'||.))
return ``[<_ db_name="`{$db_name}`">{
  collection("`{$db_name}`")//profile transform with {
`{string-join($labels!``[    insert node attribute {"`{$util:vleUtilSortKey||.}`"} {"`{$profile:sortValue}`"} as first into .]``, ',&#x0a;')}`
  }}
</_>]``
};

declare function _:get-entries-selected-by-query($dict as xs:string, $profile as document-node(), $query-template as xs:string, $query-value as xs:string) as element()* {
  let $get-entries-selected-by-query-scritps := _:create-queries-for-dbs($dict, $profile, $query-value, $query-template, false()),
    (: $log-script1 := _:write-log($get-entries-selected-by-query-scritps[1], 'INFO'), :)
    $found-in-parts := if (exists($get-entries-selected-by-query-scritps))
      then util:evals($get-entries-selected-by-query-scritps, (),
        'get-entries-selected-by-query-scritps', true()) else ()
return $found-in-parts
};

declare function _:create-queries-for-dbs($dict as xs:string, $profile as document-node(), $noSubstQuery as xs:string, $template as xs:string, $count_only as xs:boolean) {
let $node-queries := profile:create-queries-for-dbs($profile, $noSubstQuery, $template, $count_only),
    $node-queries-without-prolog := $node-queries!replace(., '((xquery)|(declare)|(module)|(import))[^;]+;\s+', '', 'm'),
    $parent-queries := for $q at $p in $node-queries
     return ``[import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
       import module namespace types = 'https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes' at 'data/elementTypes.xqm';
     `{if (matches($q, '^\s*declare\s+namespace\s')) then '(: using namespace declared in template :)'
       else string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`]``||
     replace($q, $node-queries-without-prolog[$p], ``[
       `{profile:generate-local-extractor-function($profile)}`
       let $results := `{$node-queries-without-prolog[$p]}`,
           $parent-nodes-to-return := ($results!types:get-first-parent-node-to-return(.))/self::node()
           (: parent count, not query result count :)
       `{if ($count_only) then ``[return count($parent-nodes-to-return)]``
                else ``[, $ret := if (count($results) > `{$_:max-direct-xml}`) then util:dehydrate($parent-nodes-to-return, local:extractor#1)
              else if (count($results) > 0) then <_ db_name="`{$dict}`">{
                for $r in $parent-nodes-to-return
                let $extracted-data := local:extractor($r)[not(. instance of attribute(ID) or . instance of attribute(xml:id))]
                return $r transform with {insert node $extracted-data as first into . }
              }</_>
              else ()
        return $ret]``}`]``, 'q')
  return $parent-queries
};

(:~ 
 : If there are more than $_:max-direct-xml results per DB then only a "dryed" representation is returned.
 : If the actual node is returned then an attribute $util:vleUtilSortKey is inserted.
 : This may throw FODC0002 if $dict||'__prof' does not exist
 :)
declare function _:get-entries-by-ids($dict as xs:string, $ids as xs:string+) {
  _:get-entries-by-ids($dict, $ids, (), ())
};

(:~ 
 : If there are more than $_:max-direct-xml results per DB then only a "dryed" representation is returned.
 : If the actual node is returned then an attribute $util:vleUtilSortKey is inserted.
 : This may throw FODC0002 if $dict||'__prof' does not exist
 :)
declare function _:get-entries-by-ids($dict as xs:string, $ids as xs:string+, $suggested_dbs as xs:string*, $max-direct-xml as xs:integer?) {
let $dicts := if (exists($suggested_dbs)) then $suggested_dbs else _:get-list-of-data-dbs($dict),
    $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $profile := profile:get($dict),
    $altLabels := map:keys(profile:get-alt-lemma-xqueries($profile)),
    $max-direct-xml := if (exists($max-direct-xml)) then $max-direct-xml else $_:max-direct-xml,
    $get-entries-by-ids-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[
      if (collection("`{$dict}`")//profile[@xml:id = `{$ids_seq}`])
      then `{_:get-profile-with-sort-xquery($dict, $altLabels)}`
      else ()]``
      else ``[import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
        `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
        `{profile:generate-local-extractor-function($profile)}`
        let $results := db:attribute("`{$dict}`", `{$ids_seq}`)/..,
            $ret := if (count($results) > `{$max-direct-xml}` and `{count($ids) > $max-direct-xml}`()) then util:dehydrate($results, local:extractor#1)
              else if (count($results) > 0) then <_ db_name="`{$dict}`">{
                for $r in $results
                let $extracted-data := local:extractor($r)[not(. instance of attribute(ID) or . instance of attribute(xml:id))]
                return $r transform with {insert node $extracted-data as first into . }
              }</_>
              else ()
        return $ret]``,
    (: $log_script1 :=  _:write-log($get-entries-by-ids-scripts[1], "INFO"),
    $log_script2 :=  _:write-log($get-entries-by-ids-scripts[2], "INFO"), :)
    $found-in-parts := if (exists($get-entries-by-ids-scripts)) then util:evals($get-entries-by-ids-scripts, (), if (exists($suggested_dbs)) then 'get-limited-entries-by-ids-script' else 'get-entries-by-ids-script', true()) else ()
return if (exists($found-in-parts)) then $found-in-parts
       else error(xs:QName('response-codes:_404'),
                           'Not found',
                           'IDs '||$ids_seq||' not found')
};

declare function _:count-entries-selected-by-query($dict as xs:string, $profile as document-node(), $query-template as xs:string, $query-value as xs:string) as xs:integer {
  let $xqueries := _:create-queries-for-dbs($dict, $profile, $query-value, $query-template, true())
  return sum(util:evals($xqueries, (), 'count-entries-selected-by-query', true()))
};

declare function _:count-entries-by-ids($dict as xs:string, $ids as xs:string+) as xs:integer {
let $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $xqueries := _:get-list-of-data-dbs($dict)!
(if (ends-with(., '__prof')) then ``[if (exists(`{$ids_seq}`[. = 'dictProfile'])) then 1 else 0]``
 else ``[import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
  count(db:attribute("`{.}`", `{$ids_seq}`))]``)
return sum(util:evals($xqueries, (), 'count-entries-by-ids', true()))  
};

(:~ 
 : If there are more than $_:max-direct-xml results per DB then only a "dryed" representation is returned.
 : If the actual node is returned then an attribute $util:vleUtilSortKey is inserted.
 :)
declare function _:get-entries-by-id-starting-with($dict_name as xs:string, $id_start as xs:string) {
let $dicts := _:get-real-dicts-id-starting-with($dict_name, $id_start),
    $profile := profile:get($dict_name),
    $data-extractor-xquery := profile:get-lemma-xquery($profile),
    $altLabels := map:keys(profile:get-alt-lemma-xqueries($profile)),
    $get-all-entries-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) then _:get-profile-with-sort-xquery($dict, $altLabels)
      else ``[import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at 'util.xqm';
        `{string-join(profile:get-xquery-namespace-decls($profile), '&#x0a;')}`
        `{profile:generate-local-extractor-function($profile)}`
        let $results := collection("`{$dict}`")//*[starts-with(@xml:id, "`{$id_start}`") or starts-with(@ID, "`{$id_start}`")],
            $ret := if (count($results) > `{$_:max-direct-xml}`) then util:dehydrate($results, local:extractor#1)
              else if (count($results) > 0) then <_ db_name="`{$dict}`">{
                for $r in $results
                let $extracted-data := local:extractor($r)[not(. instance of attribute(ID) or . instance of attribute(xml:id))]
                return $r transform with {insert node $extracted-data as first into . }
              }</_>
              else ()
        return $ret]``,
    (: $log_scripts :=  _:write-log($get-all-entries-scripts[1]||"&#x0a;"||$get-all-entries-scripts[2], "INFO"), :)
    $found-in-parts := if (exists($get-all-entries-scripts)) then util:evals($get-all-entries-scripts, (),    
    'get-entries-by-id-starting-with', true()) else ()
return $found-in-parts
};

declare function _:count-entries-by-id-starting-with($dict_name as xs:string, $id_start as xs:string) {
let $xqueries := _:get-list-of-data-dbs($dict_name)!
(if (ends-with(., '__prof')) then ``[if (starts-with('dictProfile', "`{$id_start}`")) then 1 else 0]``
 else ``[import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
  count(index:attributes("`{.}`", "`{$id_start}`")!db:attribute("`{.}`", .)[. instance of attribute(xml:id) or attribute(ID)])]``)
return sum(util:evals($xqueries, (), 'count-entries-by-id-starting-with', true()))  
};

declare function _:do-get-index-data($c as document-node()*, $id as xs:string*, $dt as xs:string?, $data-extractor-xquery as function(node()) as attribute()*?) {
  _:do-get-index-data($c, $id, $dt, $data-extractor-xquery, $_:max-direct-xml)
};

declare function _:do-get-index-data($c as document-node()*, $id as xs:string*, $dt as xs:string?, $data-extractor-xquery as function(node()) as attribute()*?, $dehydrate-more-than-results as xs:integer) {
  let (: $start-time := prof:current-ms(), :)
      (: $log := _:write-log('do-get-index-data base-uri($c) '||string-join($c!base-uri(.), '; ') ||' $id := '||$id, 'DEBUG'), :)
      $all-entries := types:get_all_entries($c),
      $results := $all-entries[(if (exists($id)) then @xml:id = $id or @ID = $id else true()) and (if (exists($dt)) then @dt = $dt else true())],
      (: $resultsLog := _:write-log('collecting entries took '||prof:current-ms() - $start-time||'ms', 'PROFILE'), :)
      (: does not work for 730 databases and ~2.5 Mio tags that would be processed to extract data :)
      $ret := if (count($results) > $dehydrate-more-than-results) then util:dehydrate($results, $data-extractor-xquery) 
              else if (count($results) > 0) then <_ db_name="{util:db-name($c)}">{
                for $r in $results
                let $extracted-data := if (exists($data-extractor-xquery)) then $data-extractor-xquery($r)[not(. instance of attribute(ID) or . instance of attribute(xml:id))] else ()
                return $r transform with {insert node $extracted-data as first into . }
              }</_>
              else ()
    (:, $retLog := _:write-log('do-get-index-data return '||string-join($results!local-name(.), '; '), 'DEBUG') :)
  return $ret
};

(: $data: map {'id': map {entry: <xml></xml>
                    status: ""
                    owner: ""}
         'id': ...}
:)

declare function _:create_new_entries($data as map(xs:string, map(xs:string, item()?)), $dict as xs:string, $changingUser as xs:string) as map(xs:string, map(xs:string, map(xs:string, item()?))) {
  let $ids_seq := ``[("`{string-join(map:keys($data), '","')}`")]``,
      $dict-is-db := util:eval(``[db:exists("`{$dict}`")]``, (), 'create-new-entries-db-exists'),
      $dataType := distinct-values(for $entry in $data?*?entry return types:get_data_type($entry)),
      $dicts := if ($dataType = 'profile') then $dict||'__prof'      
                else if ($dict-is-db) then $dict
                else _:get-list-of-data-dbs($dict),  
    (: iterate over all databases for the current dictionary and look for ID duplicates :)
      $collection-with-existing-id-scripts := for $dict in $dicts
        return ``[collection("`{$dict}`")//*[@xml:id = `{$ids_seq}` or @ID = `{$ids_seq}`]/db:name(.)]``,
      (: $log := _:write-log("acc:add-entry-todb "||$collection-with-existing-id-scripts[1], "DEBUG"), :)
      $collection-with-existing-id := util:evals(
            $collection-with-existing-id-scripts, (),
            'existing-ids', true()
        ),
      $check_new_node_has_unique_id := if (not(exists($collection-with-existing-id))) then true()
        else error(xs:QName('response-codes:_409'),
                  'Duplicate @xml:id or @ID',
                  "One of "||$ids_seq||" already exists in collection '"||string-join(distinct-values($collection-with-existing-id), ',')||"'"),
      $check_only_one_dataType := if (count($dataType) = 1) then true()
        else error(xs:QName('response-codes:_422'),
                  'Cannot handle entries with multiple dataTypes',
                  "There are entries of the follwing types: "||string-join($dataType, ', ')),  
      (: TODO: Should we split a sequence of new entries so the maximum number of entries per db is never exceeded? :)
      $target-collection := _:get-collection-name-for-insert-data($dict, $dataType),
      $data-with-change := map:merge(map:for-each($data, function ($id, $data){ _:add-change-records($id, $data, map{'entry': ()}, $dataType, $changingUser)})),
      $add-entry-todb-script := ``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare variable $data-with-change external;
            (_:insert-data(collection("`{$target-collection}`"), $data-with-change?*?entry, "`{$dataType}`"),
            db:optimize("`{$target-collection}`"),
            update:output(map:merge(for $id in map:keys($data-with-change)
              return map {$id: map:merge((map{'db_name': "`{$target-collection}`"}, $data-with-change($id)))})))
          ]``,
        (: $log := _:write-log('acc:add-entry-todb $add-entry-todb-script := '||$add-entry-todb-script||' $data-with-change := '||serialize($data-with-change, map{'method': 'basex'}), 'DEBUG'), :)
      $create_data_db := if ($dataType = 'profile') then _:create-new-data-db(document{$data?*?entry}) else (),
      $script_ret := util:eval($add-entry-todb-script, map {
            'data-with-change': $data-with-change
          }, 'add-entry-todb', true())
    (: , $log := _:write-log('acc:add-entry-todb $script_ret := '||serialize($script_ret, map{'method': 'basex'}), 'DEBUG') :)
return map {'current':$script_ret}
};

(: returns map {'current': map {'$id': map {'entry': <entry/>,
                                            'db_name': $target-collection}},
                                '$id': ...}
:)

declare function _:create_new_file($data as map(xs:string, item()?), $dict as xs:string, $changingUser as xs:string) as map(xs:string, map(xs:string, map(xs:string, item()?))) {
  let $dataTypes := distinct-values(for $entry in $data?xmlData//(*:entry, *:cit) return types:get_data_type($entry)),
      $target-collection := _:get-collection-name-for-insert-data($dict, $dataTypes[1]),
      $add-file-todb-script := ``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare variable $data external;
            (db:replace("`{$target-collection}`", $data?fileName, $data?xmlData),
            db:optimize("`{$target-collection}`"),
            update:output(map:merge(for $id as xs:string in $data('xmlData')//(*:entry, *:cit)/@xml:id!xs:string(.)
              return map {$id: map:merge((map{'db_name': "`{$target-collection}`"}, map{'entry': $data?xmlData//(*:entry, *:cit)[@xml:id = $id]}))})))
          ]``,
        $log := _:write-log('acc:add-file-todb $add-entry-todb-script := '||$add-file-todb-script||' $data := '||serialize($data, map{'method': 'basex'}), 'DEBUG'),
      $script_ret := util:eval($add-file-todb-script, map {
            'data': $data
          }, 'add-file-todb', true())
    , $log := _:write-log('acc:add-file-todb $script_ret := '||serialize($script_ret, map{'method': 'basex'}), 'DEBUG')
return map {'current':$script_ret}
};

declare %private function _:add-change-records($id as xs:string, $data as map(*), $oldData as map(*), $dataType as xs:string, $changingUser as xs:string) {
  map {$id: if ($dataType = 'profile') then map:merge((map{ 'entry': $data?entry transform with { chg:add-change-record-to-profile(.) }}, $data))
  else map:merge((map{ 'entry': $data?entry transform with { chg:add-change-record(., $oldData?entry//*:fs[@type = ('create', 'change', 'status')], $data?status, $data?owner, $changingUser) }}, $data))}
};

(: $data: map {'id': map {entry: <xml></xml>
                    status: ""
                    owner: ""}
         'id': ...}
:)

declare function _:change_entries($data as map(xs:string, map(xs:string, item()?)), $dict as xs:string, $changingUser as xs:string) {
(: value as map(xs:string, map(xs:string, map(xs:string, item()?))) :)
  let $entriesToReplace := _:find_entry_as_dbname_pre($dict, map:keys($data)),
      $db_names := map:keys($entriesToReplace),
      (: $_ := _:write-log("data-access:change_entries$data "||serialize($data, map{'method': 'basex'})), :)
      $befores := map:merge((for $db_name in $db_names
        let $ids := map:keys($entriesToReplace($db_name)),
            $ids_chsums := map:merge($ids!map{.: xs:string($data(.)?storedEntryMd5)})
        return chg:save-entry-in-history($dict, $db_name, $ids_chsums))),
      (: $_ := _:write-log(serialize($data, map{'method': 'basex'})), :)
      $newEntriesWithChange := map:merge(for $db_name in $db_names return
        for $id in map:keys($entriesToReplace($db_name)) return
           _:add-change-records($id, $data($id), $befores($id), types:get_data_type($data($id)?entry), $changingUser)
        ),
      (: $_ := _:write-log(serialize($newEntriesWithChange, map{'method': 'basex'})), :)
      $ret := for $db_name in $db_names
        let $ids := map:keys($entriesToReplace($db_name)),
            $before := map:merge((for $k in map:keys($befores)
              where $befores($k)?db_name = $db_name
              return map{$k: $befores($k)})),
            $current := _:do-replace-entry-by-id($db_name, $ids, $newEntriesWithChange)
        return map{
          'before': $before,
          'current': $current
  }
  return $ret
};

(: returns map {'current': map {'$id': map {'entry': <entry/>,
                                            'db_name': $target-collection}},
                                '$id': ...},
                'before': map {'$id': map {'entry': <entry/>,
                                            'db_name': $target-collection}},
                                '$id': ...}
:)

declare function _:find_entry_as_dbname_pre($dict_name as xs:string, $ids as xs:string+) as map(xs:string, map(xs:string, item())) {
let $ids_seq := ``[("`{string-join($ids, '","')}`")]``
return util:eval(``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $db_names := data-access:get-real-dicts("`{$dict_name}`", `{$ids_seq}`),
        $entries := $db_names!map{.: data-access:find_entry_as_dbname_pre_with_collection(collection(.), `{$ids_seq}`)}
    return map:merge($entries)
    ]``, (), 'find_entry_as_dbname_pre', true())  
};

(: returns map {$db_name: map {$id: map {'pre': $pre,
                                         'owner': $owner},
                               $id: ...},
                $db_name: ...}               
:)

declare function _:find_entry_as_dbname_pre_with_collection($collection as document-node()*, $ids as xs:string+) as map(*)+ {
  let $entries := $collection//*[(@xml:id, @ID) = $ids] 
  return map:merge($entries!map{xs:string(./(@xml:id, @ID)): map {"pre": db:node-pre(.), 'owner': ./*:fs[@type='change']/*[@name='owner']/*/@value/data()}})
};

declare %private function _:do-replace-entry-by-id($db-name as xs:string, $ids as xs:string+, $newEntries as map(xs:string, item())) as map(xs:string, map(xs:string, item()?)) {
let $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $_ := _:write-log("data-access:do-replace-entry-by-id$newEntries "||serialize($newEntries, map {"method": "basex"}))
return util:eval(``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    declare variable $newEntries as map(xs:string, item()) external;
    let $entriesToChange := data-access:find_entry_as_dbname_pre_with_collection(collection("`{$db-name}`"), `{$ids_seq}`)
      (: , $log := data-access:write-log(serialize($entriesToChange, map{'method': 'basex'}), 'INFO')
      , $log := data-access:write-log(serialize($newEntries, map{'method': 'basex'}), 'INFO') :)
    return for $id in map:keys($entriesToChange) return replace node db:open-pre("`{$db-name}`", $entriesToChange($id)?pre) with $newEntries($id)?entry,
    db:optimize("`{$db-name}`"),
    update:output(map:merge(for $id in map:keys($newEntries)
     return map{xs:string($id): map{'entry': $newEntries($id)?entry,
                         'db_name': "`{$db-name}`"}}))
  ]``, map {'newEntries': $newEntries}, 'replace-entry-by-id', true())  
};

declare function _:delete_entry($dict as xs:string, $id as xs:string, $changingUser as xs:string) as map(xs:string, item()) {
  let $entryToDelete := _:find_entry_as_dbname_pre($dict, $id),
      $db-name := map:keys($entryToDelete)
  return map {'api-response': (chg:save-entry-in-history-before-deletion($dict, $db-name, $id, $changingUser),
          _:do-delete-entry-by-id($db-name, $id))[2],
    'db_name': $db-name
  }
};

declare %private function _:do-delete-entry-by-id($db-name as xs:string, $id as xs:string) as element(rfc-7807:problem) {
  util:eval(``[import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
    import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $entryToDelete := data-access:find_entry_as_dbname_pre_with_collection(collection("`{$db-name}`"), "`{$id}`")
    return delete node db:open-pre("`{$db-name}`", $entryToDelete?*("pre")),
    db:optimize("`{$db-name}`"),
    update:output(<problem xmlns="urn:ietf:rfc:7807">
       <type>https://tools.ietf.org/html/rfc7231#section-6</type>
       <title>{$api-problem:codes_to_message(204)}</title>
       <status>204</status>
    </problem>
  )
  ]``, (), 'delete-entry-by-id', true())
};

declare %updating function _:insert-data($c as document-node()*, $data as element()+, $dataType as xs:string) {
  let $parentNode := try {
        types:get-parent-node-for-element($c, $dataType)
      } catch err:XPTY0004 { (: multi part dict type :)
        types:get-parent-node-for-element($c, "_")
      }
      (: let $log := _:write-log("method access:insert-data() - parent node: " || $parentNode || " data type: " || $dataType || " data: " || serialize($data)) :)
      (: , $log := l:write-log('wde:insert-data doc '||base-uri($c)||' index '||$index, 'DEBUG') :)
  return if ($parentNode instance of document-node() and exists($parentNode/*)) then replace node $parentNode/* with $data
    else insert node $data into if(empty($parentNode)) then types:get-parent-node-for-element($c, "_") else $parentNode
};

declare %private function _:get-collection-name-for-insert-data($dict as xs:string, $dataType as xs:string) as xs:string {
    let $db-exists := util:eval(``[db:exists("`{$dict}`")]``, (), 'add-entry-todb-db-exists'),        
        $profile := if ($dataType = 'profile') then document {} else profile:get($dict),
        $dicts := if ($dataType = 'profile') then $dict||'__prof'
                  else if ($db-exists) then $dict
                  else profile:get-list-of-data-dbs($profile),
       (: $log := _:write-log('acc:get-collection-name-for-insert-data count(acc:count-current-items($dicts[last()], $dataType)/*) >= acc:get-split-every($profile): '
                           ||acc:count-current-items($dicts[last()], $dataType)||' >= '||acc:get-split-every($profile), 'DEBUG'), :)
        $ret := if (empty($dicts) or _:count-current-items($dicts[last()], $dataType) >= profile:get-split-every($profile)) then _:create-new-data-db($profile) else $dicts[last()]
      (:, $retLog := _:write-log('acc:get-collection-name-for-insert-data return '||$ret, 'DEBUG') :)
    return $ret
};

declare %private function _:count-current-items($dict as xs:string?, $dataType as xs:string) as xs:integer {
  let $count-current-script := ``[import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
    let $ret := count(types:get-parent-node-for-element(collection("`{$dict}`"), "`{$dataType}`")/*)
    return if ($ret > 0) then $ret else count(types:get-parent-node-for-element(collection("`{$dict}`"), "_")/*)
  ]``
  return if (empty($dict)) then 0 else util:eval($count-current-script, (), 'count-current-items', true())
};

declare %private function _:create-new-data-db($profile as document-node()) as xs:string {
  let $check-profile-contains-valid-dictname := profile:check-contains-valid-dictname($profile),
      $current-dict-parts := profile:get-list-of-data-dbs($profile),
      $new-db-name := profile:get-name-for-new-db($profile, count($current-dict-parts)),
      (: $log := _:write-log('Trying to create '||$new-db-name, 'DEBUG'), :)
      (: TODO: read different options from profiles. :)
      $index-options := map:merge((map {}, $_:default_index_options)),
    $create-new-data-db-script := ``[
    import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    declare variable $index-options external;
    db:create("`{$new-db-name}`", document {<_ xmlns=""></_>}, "`{$new-db-name}`.xml", $index-options)
  ]``,
    $create-new-data-db := util:eval($create-new-data-db-script, map{'index-options': $index-options}, 'create-new-data-db', true()),
    $ret := profile:get-list-of-data-dbs($profile)[last()]
    (: , $retLog := _:write-log('Created '||$new-db-name, 'DEBUG') :)
  return $ret
};

declare (: %private :) function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
declare %private function _:write-log($message as xs:string) {
  if ($_:enable_trace) then admin:write-log($message,"trace")
};
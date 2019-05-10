xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mds = "http://www.loc.gov/mods/v3";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace rfc-7807 = "urn:ietf:rfc:7807";

declare variable $_:basePath as xs:string := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:selfName as xs:string := tokenize(static-base-uri(), '/')[last()];
declare variable $_:default_split_every as xs:integer := 60000;
declare variable $_:enable_trace := true();
declare variable $_:default_index_options := map{'textindex': true(), 
                                                 'attrindex': true(),
                                                 'ftindex': true(), 'casesens': false(), 'diacritics': false(), 'language': 'en',
                                                 'maxlen':192, 'maxcats':1000,'splitsize': 20};
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
  let $log := _:write-log('acc:get-list-of-data-dbs $dict := '||$dict, 'DEBUG'),
      $ret := ($dict||'__prof', _:get-list-of-data-dbs-from-profile(_:get-profile($dict)), _:get-skel-if-exists($dict))
    , $logRet := _:write-log('acc:get-list-of-data-dbs return '||string-join($ret, '; '), 'DEBUG')
  return $ret
};

declare %private function _:get-skel-if-exists($dict as xs:string) as xs:string? {
  util:eval(``[db:list()[. = "`{$dict}`__skel"]]``, (), 'get-ske-if-exists')
};

declare function _:get-entry-by-id($dict_name as xs:string, $id as xs:string) {
  let $dict_name := _:get-real-dict($dict_name, $id)
  return util:eval(``[collection("`{$dict_name}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]]``, (), 'getDictDictNameEntry')  
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

(: this may throw FODC0002 if $dict||'__prof' does not exist :)
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
                       $c/profile,
                       $c//tei:TEI,
                       $c//tei:form[@type = 'lemma'],
                       $c//mds:mods,
                       $c//tei:entry,
                       $c//tei:entryFree),
      $results := $all-entries[(if (exists($id)) then @xml:id = $id or @ID = $id else true()) and (if (exists($dt)) then @dt = $dt else true())]
    , $retLog := _:write-log('do-get-index-data return '||string-join($results!local-name(.), '; '), 'DEBUG')
  return if (count($results) > 25) then util:dehydrate($results) else $results
};

declare function _:save_new_entry($data as element(), $dict as xs:string) as element(rfc-7807:problem) {
  let $id := $data/(@xml:id, @ID),
      $db-exists := util:eval(``[db:exists("`{$dict}`")]``, (), 'add-entry-todb-db-exists'),
      $dataType := _:get_data_type($data),
      $dicts := if ($db-exists) then $dict
                else if ($dataType = 'profile') then $dict||'__prof'
                else _:get-list-of-data-dbs($dict),
    (: TODO: There should be some heuristic to decide whether the new entry should go into a new database or not. :)
      $target-collection := _:get-collection-name-for-insert-data($dict, $dataType)
    (: iterate over all databases for the current dictionary and look for ID duplicates :)
    let $check_new_node_has_id := if (exists($id)) then true()
        else error(xs:QName('response-codes:_422'),
                  '@xml:id or @ID missing on data node',
                  'Element '||$data/local-name()||' needs to have either an xml:id attribute or an ID attribute.'),
        $collection-with-existing-id-scripts := for $dict in $dicts
        return ``[collection("`{$dict}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]/db:name(.)]``,
        $log := _:write-log("acc:add-entry-todb "||$collection-with-existing-id-scripts[1], "DEBUG"),
        $collection-with-existing-id := util:evals(
            $collection-with-existing-id-scripts, (),
            'existing-ids', true()
        ),
        $check_new_node_has_unique_id := if (not(exists($collection-with-existing-id))) then true()
        else error(xs:QName('response-codes:_422'),
                  'Duplicate @xml:id or @ID',
                   $id||" already exists in collection '"||string-join(distinct-values($collection-with-existing-id), ',')||"'"),                  
        $add-entry-todb-script := ``[ import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
            import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
            declare variable $data external;
            (_:insert-data(collection("`{$target-collection}`"), $data, "`{$dataType}`"),
            update:output(
            <problem xmlns="urn:ietf:rfc:7807">
                <type>https://tools.ietf.org/html/rfc7231#section-6</type>
                <title>{$api-problem:codes_to_message(204)}</title>
                <status>204</status>
            </problem>
            ))
          ]``,
          $log := _:write-log('acc:add-entry-todb $add-entry-todb-script := '||$add-entry-todb-script||' $data := '||serialize($data), 'DEBUG')
          return util:eval($add-entry-todb-script, map {
            'data': $data
          }, 'add-entry-todb', true())
};

declare %updating function _:insert-data($c as document-node()*, $data as element(), $dataType as xs:string) {
  let $parentNode := try {
        _:get-parent-node-for-element($c, $dataType)
      } catch err:XPTY0004 (: multi part dict type :) {
        _:get-parent-node-for-element($c, "_")
      }
    (: , $log := l:write-log('wde:insert-data doc '||base-uri($c)||' index '||$index, 'DEBUG') :)
  return if ($parentNode instance of document-node()) then replace node $parentNode/* with $data
    else insert node $data into if(empty($parentNode)) then _:get-parent-node-for-element($c, "_") else $parentNode
};

declare %private function _:get_data_type($data as element()) as xs:string {
  typeswitch ($data)
    case element(mds:mods) return 'mods'
    case element(tei:entry) return 'entry'
    case element(tei:TEI) return 'TEI'
    case element(profile) return 'profile'
    case element(tei:header) return 'header'
    case element(tei:cit) return 'example'
    case element(tei:entryFree) return 'entryFree'
    case element(_) return '_'
    default return error(xs:QName('_:error'), 'Unknown data type')
};

declare %private function _:get-collection-name-for-insert-data($dict as xs:string, $dataType as xs:string) as xs:string {
    let $db-exists := util:eval(``[db:exists("`{$dict}`")]``, (), 'add-entry-todb-db-exists'),        
        $profile := if ($dataType = 'profile') then document {} else _:get-profile($dict),
        $dicts := if ($db-exists) then $dict
                  else if ($dataType = 'profile') then $dict||'__prof'
                  else _:get-list-of-data-dbs-from-profile($profile),
       (: $log := _:write-log('acc:get-collection-name-for-insert-data count(acc:count-current-items($dicts[last()], $dataType)/*) >= acc:get-split-every($profile): '
                           ||acc:count-current-items($dicts[last()], $dataType)||' >= '||acc:get-split-every($profile), 'DEBUG'), :)
        $ret := if (empty($dicts) or _:count-current-items($dicts[last()], $dataType) >= _:get-split-every($profile)) then _:create-new-data-db($profile) else $dicts[last()]
      (:, $retLog := _:write-log('acc:get-collection-name-for-insert-data return '||$ret, 'DEBUG') :)
    return $ret
};

declare %private function _:get-split-every($profile as document-node()) as xs:integer {
  if ($profile/profile/tableName/@split-every) then xs:integer($profile/profile/tableName/@split-every) else $_:default_split_every
};

declare %private function _:count-current-items($dict as xs:string?, $dataType as xs:string) as xs:integer {
  let $count-current-script := ``[
    import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $ret := count(_:get-parent-node-for-element(collection("`{$dict}`"), "`{$dataType}`")/*)
    return if ($ret > 0) then $ret else count(_:get-parent-node-for-element(collection("`{$dict}`"), "_")/*)
  ]``
  return if (empty($dict)) then 0 else util:eval($count-current-script, (), 'count-current-items', true())
};

declare function _:get-parent-node-for-element($c as document-node()*, $dataType as xs:string) as node()* {
    switch($dataType)
        case "mods" return $c/mds:modsCollection
        case "TEI" return $c/tei:teiCorpus
        case "profile" return $c
        case "header" return $c/tei:TEI
        case "example"  return $c/tei:TEI/tei:text/tei:body/tei:div[@type='examples']
        case "cit"  return $c/tei:TEI/tei:text/tei:body/tei:div[@type='examples']
        case "entry"  return $c/tei:TEI/tei:text/tei:body/tei:div[@type='entries']
        case "entryFree"  return $c/tei:TEI/tei:text/tei:body/tei:div[@type='entries']
        case "_" return $c/*:_
        default return $c/tei:TEI/tei:text/tei:body
};

declare %private function _:create-new-data-db($profile as document-node()) as xs:string {
  let $current-dict-parts := _:get-list-of-data-dbs-from-profile($profile),
      $new-db-name := data($profile/profile/tableName/@generate-db-prefix)||format-integer(count($current-dict-parts), '000'),
      $log := _:write-log('Trying to create '||$new-db-name, 'DEBUG'),
      (: TODO: read different options from profiles. :)
      $index-options := map:merge((map {}, $_:default_index_options)),
      $create-new-data-db-script := ``[
    import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    declare variable $index-options external;
    db:create("`{$new-db-name}`", document {<_ xmlns=""></_>}, "`{$new-db-name}`.xml", $index-options)
  ]``,
    $create-new-data-db := util:eval($create-new-data-db-script, map{'index-options': $index-options}, 'create-new-data-db', true()),
    $ret := _:get-list-of-data-dbs-from-profile($profile)[last()],
    $retLog := _:write-log('Created '||$new-db-name, 'DEBUG')
  return $ret
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
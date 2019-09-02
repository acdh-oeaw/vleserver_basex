xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'elementTypes.xqm';
import module namespace chg = "https://www.oeaw.ac.at/acdh/tools/vle/data/changes" at 'changes.xqm';

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mds = "http://www.loc.gov/mods/v3";
declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
declare namespace rfc-7807 = "urn:ietf:rfc:7807";

declare variable $_:basePath as xs:string := string-join(tokenize(static-base-uri(), '/')[last() > position()], '/');
declare variable $_:selfName as xs:string := tokenize(static-base-uri(), '/')[last()];
declare variable $_:default_split_every as xs:integer := 60000;
declare variable $_:enable_trace := false();
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
  let (: $log := _:write-log('acc:get-list-of-data-dbs $dict := '||$dict, 'DEBUG'), :)
      $ret := ($dict||'__prof', _:get-list-of-data-dbs-from-profile(_:get-profile($dict)), _:get-skel-if-exists($dict))
      (: , $logRet := _:write-log('acc:get-list-of-data-dbs return '||string-join($ret, '; '), 'DEBUG') :)
  return $ret
};

declare %private function _:get-skel-if-exists($dict as xs:string) as xs:string? {
  util:eval(``[db:list()[. = "`{$dict}`__skel"]]``, (), 'get-ske-if-exists')
};

declare function _:get-entry-by-id($dict_name as xs:string, $id as xs:string) as element() {
  let $dict_name := _:get-real-dict($dict_name, $id)
  return util:eval(``[collection("`{$dict_name}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]]``, (), 'getDictDictNameEntry')  
};

declare function _:get-real-dict($dict as xs:string, $id as xs:string) as xs:string {
let $dicts := _:get-list-of-data-dbs($dict),
    $get-db-for-id-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) 
      then ``[if (collection("`{$dict}`")//profile[(@xml:id, @ID) = "`{$id}`"]) then "`{$dict}`" else ()]``
      else ``[
            import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare variable $id as xs:string external;
            let $orig := db:attribute("`{$dict}`", $id)[local-name() = ('id', 'ID')]
            return if ($orig) then "`{$dict}`" else ()
            ]``,
    $found-in-parts := if (exists($get-db-for-id-scripts)) then util:evals($get-db-for-id-scripts, map {
              'id': $id
            }, 'get-db-for-id-script', true()) else ()
return if (exists($found-in-parts)) then $found-in-parts
       else error(xs:QName('response-codes:_404'),
                           'Not found',
                           'ID '||$id||' not found')
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

(: this may throw FODC0002 if $dict||'__prof' does not exist :)
declare function _:get-entries-by-ids($dict as xs:string, $ids as xs:string+) {
let $dicts := _:get-list-of-data-dbs($dict),
    $ids_sequence := ``[("`{string-join($ids, '","')}`")]``,
    $get-all-entries-scripts := for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[collection("`{$dict}`")//profile[@xml:id = `{$ids_sequence}`]]``
      else ``[
            import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            _:do-get-index-data(collection("`{$dict}`"), `{$ids_sequence}`, ())
            ]``,
    $log_scripts :=  _:write-log($get-all-entries-scripts[1]||"&#x0a;"||$get-all-entries-scripts[2], "INFO"),
    $found-in-parts := if (exists($get-all-entries-scripts)) then util:evals($get-all-entries-scripts, (),    
    'get-all-entries-script', true()) else ()
return $found-in-parts
};

declare function _:do-get-index-data($c as document-node()*, $id as xs:string*, $dt as xs:string?) {
  let $start-time := prof:current-ms(),
    (:, $log := _:write-log('do-get-index-data base-uri($c) '||string-join($c!base-uri(.), '; ') ||' $id := '||$id, 'DEBUG'), :)
      $all-entries := types:get_all_entries($c),
      $results := $all-entries[(if (exists($id)) then @xml:id = $id or @ID = $id else true()) and (if (exists($dt)) then @dt = $dt else true())],
      (: $resultsLog := _:write-log('collecting entries took '||prof:current-ms() - $start-time||'ms', 'PROFILE'), :)
      $ret := if (count($results) > 25) then util:dehydrate($results) else $results
    (:, $retLog := _:write-log('do-get-index-data return '||string-join($results!local-name(.), '; '), 'DEBUG') :)
  return $ret
};

declare function _:create_new_entry($data as element(), $dict as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as element() {
  let $id := $data/(@xml:id, @ID),
      $db-exists := util:eval(``[db:exists("`{$dict}`")]``, (), 'add-entry-todb-db-exists'),
      $dataType := types:get_data_type($data),
      $dicts := if ($dataType = 'profile') then $dict||'__prof'      
                else if ($db-exists) then $dict
                else _:get-list-of-data-dbs($dict),  
    (: iterate over all databases for the current dictionary and look for ID duplicates :)
      $collection-with-existing-id-scripts := for $dict in $dicts
        return ``[collection("`{$dict}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]/db:name(.)]``,
        $log := _:write-log("acc:add-entry-todb "||$collection-with-existing-id-scripts[1], "DEBUG"),
        $collection-with-existing-id := util:evals(
            $collection-with-existing-id-scripts, (),
            'existing-ids', true()
        ),
      $check_new_node_has_unique_id := if (not(exists($collection-with-existing-id))) then true()
        else error(xs:QName('response-codes:_409'),
                  'Duplicate @xml:id or @ID',
                   $id||" already exists in collection '"||string-join(distinct-values($collection-with-existing-id), ',')||"'"),                  
     
       (: TODO: There should be some heuristic to decide whether the new entry should go into a new database or not. :)
       $target-collection := _:get-collection-name-for-insert-data($dict, $dataType),
       $data-with-change := if ($dataType = 'profile') then $data transform with { chg:add-change-record-to-profile(.) }
                            else $data transform with { chg:add-change-record(., .//*:fs[@type = 'change'], $status, $owner, $changingUser) },
       $add-entry-todb-script := ``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
            declare variable $data-with-change external;
            (_:insert-data(collection("`{$target-collection}`"), $data-with-change, "`{$dataType}`"),
            db:optimize("`{$target-collection}`"),
            update:output($data-with-change))
          ]``
        (: , $log := _:write-log('acc:add-entry-todb $add-entry-todb-script := '||$add-entry-todb-script||' $data := '||serialize($data), 'DEBUG') :)
          return (
          if ($dataType = 'profile') then
          _:create-new-data-db(document{$data}) else "",
          util:eval($add-entry-todb-script, map {
            'data-with-change': $data-with-change
          }, 'add-entry-todb', true()))[2]
};

declare function _:change_entry($newEntry as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as element() {
  let $entryToReplace := _:find_entry_as_dbname_pre($dict, $id),
      $newEntryWithChange := if (types:get_data_type($newEntry) = 'profile') then $newEntry transform with { chg:add-change-record-to-profile(.) }
                             else $newEntry transform with { chg:add-change-record(., $entryToReplace[1], $entryToReplace[2], $status, $owner, $changingUser) }
  return (chg:save-entry-in-history($dict, $entryToReplace[1], $entryToReplace[2]),
          _:do-replace-entry-by-pre($entryToReplace[1], $entryToReplace[2], $newEntryWithChange))
};

declare %private function _:find_entry_as_dbname_pre($dict_name as xs:string, $id as xs:string) as xs:anyAtomicType+ {
util:eval(``[import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $dict_name := data-access:get-real-dict("`{$dict_name}`", "`{$id}`"),
        $entry := collection($dict_name)//*[(@xml:id, @ID) = "`{$id}`"] 
    return ($dict_name, db:node-pre($entry), $entry//*:fs[@type='change']/*[@name='owner']/*/@value/data())
    ]``, (), 'find-entry-for-delete', true())  
};

declare %private function _:do-replace-entry-by-pre($db-name as xs:string, $pre as xs:integer, $newEntry as element()) as element() {
  util:eval(``[declare variable $newEntry as element() external;
    replace node db:open-pre("`{$db-name}`", `{$pre}`) with $newEntry,
    db:optimize("`{$db-name}`"),
    update:output($newEntry)
  ]``, map {'newEntry': $newEntry}, 'replace-entry-by-pre', true())  
};

declare function _:delete_entry($dict as xs:string, $id as xs:string, $changingUser as xs:string) as element(rfc-7807:problem) {
  let $entryToDelete := _:find_entry_as_dbname_pre($dict, $id)
  return (chg:save-entry-in-history-before-deletion($dict, $entryToDelete[1], $entryToDelete[2], $changingUser),
          _:do-delete-entry-by-pre($entryToDelete[1], $entryToDelete[2]))
};

declare %private function _:do-delete-entry-by-pre($db-name as xs:string, $pre as xs:integer) as element(rfc-7807:problem) {
  util:eval(``[import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
    delete node db:open-pre("`{$db-name}`", `{$pre}`),
    db:optimize("`{$db-name}`"),
    update:output(<problem xmlns="urn:ietf:rfc:7807">
       <type>https://tools.ietf.org/html/rfc7231#section-6</type>
       <title>{$api-problem:codes_to_message(204)}</title>
       <status>204</status>
    </problem>
  )
  ]``, (), 'delete-entry-by-pre', true())
};

declare %updating function _:insert-data($c as document-node()*, $data as element(), $dataType as xs:string) {
  let $parentNode := try {
        types:get-parent-node-for-element($c, $dataType)
      } catch err:XPTY0004 (: multi part dict type :) {
        types:get-parent-node-for-element($c, "_")
      }
    (: , $log := l:write-log('wde:insert-data doc '||base-uri($c)||' index '||$index, 'DEBUG') :)
  return if ($parentNode instance of document-node() and exists($parentNode/*)) then replace node $parentNode/* with $data
    else insert node $data into if(empty($parentNode)) then types:get-parent-node-for-element($c, "_") else $parentNode
};

declare %private function _:get-collection-name-for-insert-data($dict as xs:string, $dataType as xs:string) as xs:string {
    let $db-exists := util:eval(``[db:exists("`{$dict}`")]``, (), 'add-entry-todb-db-exists'),        
        $profile := if ($dataType = 'profile') then document {} else _:get-profile($dict),
        $dicts := if ($dataType = 'profile') then $dict||'__prof'
                  else if ($db-exists) then $dict
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
  let $count-current-script := ``[import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
    let $ret := count(types:get-parent-node-for-element(collection("`{$dict}`"), "`{$dataType}`")/*)
    return if ($ret > 0) then $ret else count(types:get-parent-node-for-element(collection("`{$dict}`"), "_")/*)
  ]``
  return if (empty($dict)) then 0 else util:eval($count-current-script, (), 'count-current-items', true())
};

declare %private function _:create-new-data-db($profile as document-node()) as xs:string {
  let $check-profile-contains-valid-dictname := 
        if ((exists($profile/profile/tableName/@generate-db-prefix) and
             exists($profile/profile/tableName/@find-dbs)) or
            exists($profile/profile/tableName/text())) then ()
        else error(xs:QName('response-codes:_422'),
                   'Profile does not contain a valid name for the data DBs',
                   'Need a "<tableName>somename</tableName>" or "<tableName generate-db-prefix="somename" find-dbs="somename\d+">somename</tableName>".&#x0a;'||
                   'Got "'||serialize($profile/profile/tableName, map{'method': 'xml'})||'".'),
      $current-dict-parts := _:get-list-of-data-dbs-from-profile($profile),
      $new-db-name := if (exists($profile/profile/tableName/@generate-db-prefix) and
                          exists($profile/profile/tableName/@find-dbs))
                      then data($profile/profile/tableName/@generate-db-prefix)||format-integer(count($current-dict-parts), '000')
                      else $profile/profile/tableName/text(),
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
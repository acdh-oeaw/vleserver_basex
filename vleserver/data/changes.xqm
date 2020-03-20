xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'elementTypes.xqm';
import module namespace functx = "http://www.functx.com";
import module namespace admin = "http://basex.org/modules/admin"; (: for logging :)

declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $_:enable_trace := false();
declare variable $_:user external := 'user doing changes not set!';

declare function _:get-pre-and-dt-for-changes-by-id($db-base-name as xs:string, $id as xs:string) as element(_)* {
  let $hist-db-name := $db-base-name||'__hist'
  return util:eval(``[collection("`{$hist-db-name}`")//*[@xml:id = "`{$id}`" or @ID = "`{$id}`"]!<_><p>{db:node-pre(.)}</p><dt>{./@dt/data()}</dt></_>]``, (), 'get-pre-and-dt-for-changes-by-id')  
};

declare function _:get-change-by-pre($db-base-name as xs:string, $pres as xs:integer*) as element()* {
  let $hist-db-name := $db-base-name||'__hist'
  return util:eval(``[`{'('||string-join($pres, ',')||')'}`!db:open-pre("`{$hist-db-name}`", `{.}`)]``, (), 'get-change-by-pre')  
};


declare function _:get-change-by-id-and-dt($db-base-name as xs:string, $id as xs:string, $dt as xs:string) as element(_)? {
  let $hist-db-name := $db-base-name||'__hist'
  return util:eval(``[collection("`{$hist-db-name}`")//*[(@xml:id = "`{$id}`" or @ID = "`{$id}`") and @dt = "`{$dt}`"]!<_><p>{db:node-pre(.)}</p><dt>{./@dt/data()}</dt><entry>{.}</entry></_>]``, (), 'get-change-by-id-and-dt')  
};


declare function _:save-entry-in-history($db-base-name as xs:string, $db-name as xs:string, $ids as xs:string+) as map(*) {
let $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
    $saved_nodes :=  util:eval(``[import module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at 'data/changes.xqm';
    import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $entriesToChange := data-access:find_entry_as_dbname_pre_with_collection(collection("`{$db-name}`"), `{$ids_seq}`)
      (: , $log := _:write-log(serialize($entriesToChange, map {'method': 'basex'}), 'INFO') :)
    (: starting with BaseX 9.3 db:open-pre() can handle a sequence itself :)
    return _:save-entry-in-history("`{$db-base-name}`", ($entriesToChange?*?pre!db:open-pre("`{$db-name}`", .)))]``, (), 'save-entry-in-history_3', true())
return map:merge($saved_nodes!map{xs:string(./(@xml:id, @ID)): map{'entry': ., 'db_name': $db-name}})
};

declare function _:save-entry-in-history-before-deletion($db-base-name as xs:string, $db-name as xs:string, $id as xs:string, $changingUser as xs:string) {
  util:eval(``[import module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at 'data/changes.xqm';
    import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
    let $entryToDelete := data-access:find_entry_as_dbname_pre_with_collection(collection("`{$db-name}`"), "`{$id}`"),
        $e := db:open-pre("`{$db-name}`", $entryToDelete?*("pre")) transform with {_:add-change-record(., .//*:fs[@type = 'change'], "deleted", "", "`{$changingUser}`")}
    return _:save-entry-in-history("`{$db-base-name}`", $e)]``, (), 'save-entry-in-history_4', true())
};

declare function _:save-entry-in-history($db-base-name as xs:string, $cur-nodes as node()+) as node()+ {
  let $hist-db-name := $db-base-name||'__hist',
      $hist-nodes := <_/> update {insert node $cur-nodes into .} update {./*!_:add-timestamp(.) }
  return (util:eval(``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/changes" at "data/changes.xqm";
       declare variable $hist-nodes external;
       (: this job only locks $hist-db-name for writes. See also db:create docs. :)      
       try { _:_save-entry-in-history(collection("`{$hist-db-name}`"), "`{$hist-db-name}`", $hist-nodes) }
       catch err:FODC0002 { db:create("`{$hist-db-name}`", <hist>{$hist-nodes/*}</hist>, "`{$hist-db-name}`.xml") }]``, map{'hist-nodes': $hist-nodes}, 'save-entry-in-history_2', true()), $cur-nodes)
};

declare %updating function _:add-change-record-to-profile($e as element(profile)) {
  if ($e/@when) then replace value of node $e/@when with format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')
  else insert node attribute {'when'} {format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')} as first into $e
};

declare function _:add-change-record($data as map(xs:string, item()?), $db-name as xs:string, $pre as xs:integer, $changingUser as xs:string) {
  util:eval(``[import module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at 'data/changes.xqm';    
    import module namespace hash = "http://basex.org/modules/hash";
    declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
    declare variable $data as map(xs:string, item()?) external;
    let $stored_entry := db:open-pre("`{$db-name}`", `{$pre}`),
        $stored_entry_md5 := string(xs:hexBinary(hash:md5(serialize($stored_entry)))),
        $check_md5_if_exists := if (not(exists($data?storedEntryMd5)) or $data?storedEntryMd5 eq $stored_entry_md5) then true()
      else error(xs:QName('response-codes:_409'),
                'Checksum mismatch.',
                "Provided md5 checksum was "||$data?storedEntryMd5||". Checksum of current entry is "||$stored_entry_md5||".")
    return _:add-change-record($data?entry, $stored_entry//*:fs[@type=('change', 'create')], $data?status, $data?owner, "`{$changingUser}`")]``,
    map{'data': $data},
    'add-change-record_5', true())
};

declare %updating function _:add-change-record($e as element(), $oldChangeEntries as element()*, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string?) {
  let $parentElement := types:get_parent_node_for_change_log($e),
      $changeEntry :=
<fs type='change' xmlns="http://www.tei-c.org/ns/1.0">
{if ($parentElement/@xml:space='preserve') then () else attribute {"xml:space"} {"preserve"}}
<f name="who"><symbol>{attribute value {($changingUser, $_:user)[1]}}</symbol></f>
<f name="when"><symbol>{attribute value {format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')}}</symbol></f>
{if (exists($status)) then <f name='status'><symbol value="{$status}"/></f> 
 else ($oldChangeEntries//*:f[@name='status'][last()], $e//*:f[@name='status'][last()])[1]}
{if (exists($owner)) then <f name='owner'><symbol value="{$owner}"/></f> 
 else ($oldChangeEntries//*:f[@name='owner'][last()], $e//*:f[@name='owner'][last()])[1]}
</fs>,
      $oldChangesSpacePreserve := $oldChangeEntries transform with {if ($parentElement/@xml:space='preserve') then () else 
        (./descendant-or-self::*:fs[not(exists(@xml:space))]!(insert node attribute {"xml:space"} {"preserve"} into .),
         delete node ./descendant-or-self::text()[normalize-space(.) eq ''],
         delete node .//*:f[@name=('owner', 'status')]) }
  return (delete node $e//*:fs[@type=('change', 'create')]/following-sibling::node()[. instance of text()][1],
    delete node $e//*:fs[@type=('change', 'create')],
    delete node $e//*:fs[@type=('change', 'create')][1]/preceding-sibling::node()[. instance of comment()][1]/following-sibling::node()[. instance of text()][1],
    delete node $e//*:fs[@type=('change', 'create')][1]/preceding-sibling::node()[. instance of comment()][1],
    delete node $e//*:f[@name=('owner', 'status')],
    if (_:check_has_old_entries_to_move($e)) then _:move_to_tei_and_add($e, $oldChangesSpacePreserve, $changeEntry)
    else insert node (comment {'read only - nicht veränderbar'}, $oldChangesSpacePreserve, $changeEntry) as last into $parentElement)
};

declare %private function _:check_has_old_entries_to_move($e as element()) as xs:boolean {
  ($e//*:fs and not($e//tei:fs)) or $e//*:fs/parent::* != types:get_parent_node_for_change_log($e)
};

declare %private %updating function _:move_to_tei_and_add($e as element(), $oldChangeEntries as element(), $newChangeEntry as element(tei:fs)) {
  let $oldChangeEntries := functx:change-element-ns-deep($oldChangeEntries, "http://www.tei-c.org/ns/1.0", '')
  return insert node (comment {'read only - nicht veränderbar'}, $oldChangeEntries, $newChangeEntry) as first into types:get_parent_node_for_change_log($e)
};

declare %updating function _:_save-entry-in-history($hist-db as document-node(), $hist-db-name as xs:string, $hist-nodes as node()+) {
  insert node $hist-nodes/* as last into $hist-db/hist
};

declare %updating function _:add-timestamp($cur-node as node()) {
   insert node (attribute dt {format-dateTime(current-dateTime(),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')}) into $cur-node 
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
declare %private function _:write-log($message as xs:string) {
    admin:write-log($message,"trace")
};
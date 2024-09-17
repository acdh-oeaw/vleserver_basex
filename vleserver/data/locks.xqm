xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/locks';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare variable $_:maxLockTime := xs:dayTimeDuration("PT15M"); (: 15 minutes :)
declare variable $_:enable_trace := false();

declare function _:lock_entry($db-base-name as xs:string, $userName as xs:string, $ids as xs:string+, $expiresAt as xs:dateTime) as xs:string {
  let $lcks-db-name := $db-base-name||'__lcks',
      $dt := format-dateTime($expiresAt,'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]'),
      $ids-string := '("'||string-join($ids, '","')||'")'
  return util:eval(``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at "data/locks.xqm";
       (: this job only locks $lcks-db-name for writes. See also db:create docs. :)      
       try { (_:_remove_expired_locks(collection("`{$lcks-db-name}`")),
              _:_lock_entry(collection("`{$lcks-db-name}`"), "`{$userName}`", `{$ids-string}`, "`{$dt}`")),
              update:output("`{$userName}`") }
       catch err:FODC0002 { db:create("`{$lcks-db-name}`", <locks>{`{$ids-string}`!<lock id="{.}" user="`{$userName}`" dt="`{$dt}`"/>}</locks>, "`{$lcks-db-name}`.xml"), update:output("`{$userName}`") }]``, (), 'lock_entry', true())
};

declare %updating function _:_lock_entry($db as document-node(), $userName as xs:string, $ids as xs:string+, $dt as xs:string) {
  for $id in $ids
  return if (exists($db//lock[@id = $id and xs:dateTime(@dt) > current-dateTime() and @user ne $userName]))
  then error(xs:QName('_:held'), 'Another user holds the lock. ', map{'user': $db//lock[@id=$id]/@user/data(), 'id': $id})
  else (
    delete node $db/locks/lock[@id = $id and @user = $userName],
    insert node <lock id="{$id}" user="{$userName}" dt="{$dt}"/> as last into $db/locks
  )
};

declare %updating function _:_remove_expired_locks($db as document-node()) {
  delete node $db//lock[xs:dateTime(data(@dt)) < current-dateTime()]
};

declare function _:get_user_locking_entry($db-base-name as xs:string, $id as xs:string) as xs:string? {
  let $lcks-db-name := $db-base-name||'__lcks',
      (: $log := _:write-log(``[looking for "`{$id}`" in "`{$lcks-db-name}`"]``, 'DEBUG'), :)
      $ret := xs:string(util:eval(``[try {collection("`{$lcks-db-name}`")//lock[@id = "`{$id}`" and xs:dateTime(@dt) > current-dateTime()][last()]/@user/data()}
                           catch err:FODC0002 {()}]``, (), 'get_user_locking_entry'))
    (: , $retLog := _:write-log(``[returned "`{$ret}`"]``, 'DEBUG') :)
  return $ret
};

declare function _:get_user_locking_entries($db-base-name as xs:string, $ids as xs:string+) as map(*) {
  let $lcks-db-name := $db-base-name||'__lcks',
      $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
      (: $log := _:write-log(``[looking for `{$ids_seq}` in "`{$lcks-db-name}`"]``, 'DEBUG'), :)
      $locks := util:eval(``[try {collection("`{$lcks-db-name}`")//lock[@id = `{$ids_seq}` and xs:dateTime(@dt) > current-dateTime()]}
                           catch err:FODC0002 {()}]``, (), 'get_user_locking_entry'),
      (: $retLog := _:write-log(``[returned `{$locks}`]``, 'DEBUG'), :)
      $ret := map:merge($locks!map { data(./@id): data(./@user)})
  return $ret
};

declare function _:get_user_locking_entries($db-base-name as xs:string) as map(*) {
  let $lcks-db-name := $db-base-name||'__lcks',
      (: $log := _:write-log(``[looking for `{$ids_seq}` in "`{$lcks-db-name}`"]``, 'DEBUG'), :)
      $locks := util:eval(``[try {collection("`{$lcks-db-name}`")//lock[xs:dateTime(@dt) > current-dateTime()]}
                           catch err:FODC0002 {()}]``, (), 'get_user_locking_entry'),
      (: $retLog := _:write-log(``[returned `{$locks}`]``, 'DEBUG'), :)
      $ret := map:merge($locks!map { data(./@id): data(./@user)})
  return $ret
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) as empty-sequence() {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
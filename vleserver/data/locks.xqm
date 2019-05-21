xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/locks';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare variable $_:maxLockTime := xs:dayTimeDuration("PT15M"); (: 15 minutes :)

declare function _:lock_entry($db-base-name as xs:string, $userName as xs:string, $id as xs:string, $expiresAt as xs:dateTime) {
  let $lcks-db-name := $db-base-name||'__lcks',
      $dt := format-dateTime($expiresAt,'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')
  return util:eval(``[import module namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/locks" at "data/locks.xqm";
       (: this job only locks $hist-db-name for writes. See also db:create docs. :)      
       try { (_:_remove_expired_locks(collection("`{$lcks-db-name}`")),
              _:_lock_entry(collection("`{$lcks-db-name}`"), "`{$userName}`", "`{$id}`", "`{$dt}`")) }
       catch err:FODC0002 { db:create("`{$lcks-db-name}`", <locks><lock id="`{$id}`" user="`{$userName}`" dt="`{$dt}`"/></locks>, "`{$lcks-db-name}`.xml") }]``, (), 'lock_entry', true())
};

declare %updating function _:_lock_entry($db as document-node(), $userName as xs:string, $id as xs:string, $dt as xs:string) {
  insert node <lock id="{$id}" user="{$userName}" dt="{$dt}"/> as last into $db/locks
};

declare %updating function _:_remove_expired_locks($db as document-node()) {
  delete node $db//lock[xs:dateTime(data(@dt)) < current-dateTime()]
};

declare function _:get_user_locking_entry($db-base-name as xs:string, $id as xs:string) as xs:string? {
  let $lcks-db-name := $db-base-name||'__lcks' 
  return util:eval(``[try {collection("`{$lcks-db-name}`")//lock[@id = "`{$id}`" and xs:dateTime(@dt) > current-dateTime()][last()]/@user/data()}
  catch err:FODC0002 {()}]``, (), 'get_user_locking_entry')
};
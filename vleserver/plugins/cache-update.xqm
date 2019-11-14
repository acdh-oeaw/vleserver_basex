xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update';
import module namespace cache = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../data/cache.xqm';
import module namespace profile = 'https://www.oeaw.ac.at/acdh/tools/vle/data/profile' at '../data/profile.xqm';

declare function _:after_created($data as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict),
    $sort-keys := ("", map:keys(profile:get-alt-lemma-xqueries($profile)))
return if (exists($profile//useCache)) then error(xs:QName('_:error'), 'Not implemented')
  else ()
};

declare function _:after_updated($data-current as element(), $data-before as element(), $dict as xs:string, $id as xs:string, $db_name as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict),
    $sort-keys := ("", map:keys(profile:get-alt-lemma-xqueries($profile)))
return if (exists($profile//useCache)) then
    if ($data-current instance of element(profile))
    then error(xs:QName('_:error'), 'Not implemented')
    else cache:refresh-cache-db($dict, $db_name, $sort-keys)
  else ()
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict),
    $sort-keys := ("", map:keys(profile:get-alt-lemma-xqueries($profile)))
return if (exists($profile//useCache)) then error(xs:QName('_:error'), 'Not implemented')
  else ()
};
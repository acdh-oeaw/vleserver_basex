xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update';
import module namespace cache = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../data/cache.xqm';
import module namespace profile = 'https://www.oeaw.ac.at/acdh/tools/vle/data/profile' at '../data/profile.xqm';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../util.xqm';

declare variable $_:logging-enabled := true();

declare function _:after_created($data as element(), $dict as xs:string, $id as xs:string, $db_name as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict)
return if (profile:use-cache($profile))
  then if ($data instance of element(profile))
    then cache:cache-all-entries($dict)
  else cache:refresh-cache-db($dict, $db_name, ("", map:keys(profile:get-alt-lemma-xqueries($profile))))
  else ()
};

declare function _:after_updated($data-current as element(), $data-before as element(), $dict as xs:string, $id as xs:string, $db_name as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict)
return if (profile:use-cache($profile)) then
    if ($data-current instance of element(profile))
    then
      let $profile := document {$data-current},
          $old-profile := document {$data-before},
          $cache-flag-changed := profile:use-cache($profile) != profile:use-cache($old-profile)
          (:, $log-cache-flag := _:write-log('cache flag changed: '||$cache-flag-changed||' current: '||profile:use-cache($profile)||' before: '||profile:use-cache($old-profile), 'INFO') :)
      return if ($cache-flag-changed) then
        if (profile:use-cache($profile))
        then cache:cache-all-entries($dict)
        else cache:remove($dict)
      else let $alt-lemma-xqueries := profile:get-alt-lemma-xqueries($profile),
          $old-alt-lemma-xqueries := profile:get-alt-lemma-xqueries($old-profile),
          $lemma-xquery-changed := profile:get-lemma-xquery($profile) != profile:get-lemma-xquery($old-profile),
          $alt-lemma-xquery-changed := for $key in map:keys($alt-lemma-xqueries)
            where $alt-lemma-xqueries($key) != $old-alt-lemma-xqueries($key)
            return $key,
          $sort-keys := (if ($lemma-xquery-changed) then '' else (), $alt-lemma-xquery-changed),
          (: $log-lemma-xquery := _:write-log('lemma xquery changed: '||$lemma-xquery-changed||' current: '||profile:get-lemma-xquery($profile)||' before: '||profile:get-lemma-xquery($old-profile), 'INFO'),
          $log-alt-lemma-xqueries := for $key in $alt-lemma-xquery-changed
            return _:write-log('current lemma xquery '||$key||': '||$alt-lemma-xqueries($key)||' before: '||$old-alt-lemma-xqueries($key), 'INFO'), :)
          $log-sort-keys := _:write-log('refreshing caches: '||string-join($sort-keys!(if (. = '') then 'default' else .), ', '), 'INFO')
      return cache:refresh-cache-db($dict, $db_name, $sort-keys)
    else
      let $sort-keys := ("", map:keys(profile:get-alt-lemma-xqueries($profile))),
          $extracted-sort-values := profile:extract-sort-values($profile, ($data-current, $data-before)),
          (: $log-sort-valus := _:write-log('sort values: '||serialize($extracted-sort-values), 'INFO'), :)
          $alt-label-postfixes := $sort-keys!(if (. ne "") then '-'||. else ''),
          $changed-values := for $alt-label-postix in $alt-label-postfixes
            where $extracted-sort-values[1]/@*[local-name() = $util:vleUtilSortKey||$alt-label-postix] !=
                  $extracted-sort-values[2]/@*[local-name() = $util:vleUtilSortKey||$alt-label-postix]
            return $alt-label-postix => replace('^-', ''),
          $log-changed-values := _:write-log('changed values: '||string-join($changed-values!(if (. = '') then 'default' else .), ', '), 'INFO')
      return cache:refresh-cache-db($dict, $db_name, $changed-values)
  else ()
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
let $profile := profile:get($dict)
return if (profile:use-cache($profile))
  then if ($id = 'dictProfile')
    then cache:remove($dict)
  else cache:refresh-cache-db($dict, $db_name, ("", map:keys(profile:get-alt-lemma-xqueries($profile))))
  else ()
};

declare function _:write-log($message as xs:string, $level as xs:string) as empty-sequence() {
  let $ns := replace(namespace-uri(<_:_/>), 'https://www.oeaw.ac.at/acdh/tools/vle/', '')
  return if ($_:logging-enabled) then admin:write-log($ns||':'||$message, $level) else ()
};
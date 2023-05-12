xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/cache-update';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at '../api-problem.xqm';
import module namespace cache = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../data/cache.xqm';
import module namespace profile = 'https://www.oeaw.ac.at/acdh/tools/vle/data/profile' at '../data/profile.xqm';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../util.xqm';

declare variable $_:logging-enabled := false();

declare function _:after_created($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_cache-update@after_created',
          prof:track(
let $profile := profile:get($dict)
return if (profile:use-cache($profile))
  then if ($data?current?*?entry instance of element(profile))
    then cache:cache-all-entries($dict)
  else cache:refresh-cache-db($dict, $db_name, ("", map:keys(profile:get-alt-lemma-xqueries($profile))))
  else map{}
))
};

declare function _:after_updated($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_cache-update@after_updated',
          prof:track(
let $profile := profile:get($dict),
    $changes := map:merge(for $id in map:keys($data?current) return
    if ($data?current($id)?entry instance of element(profile))
    then
      let $profile := document {$data?current($id)?entry},
          $old-profile := document {$data?before($id)?entry},
          $cache-flag-changed := profile:use-cache($profile) != profile:use-cache($old-profile)
          (:, $log-cache-flag := _:write-log('cache flag changed: '||$cache-flag-changed||' current: '||profile:use-cache($profile)||' before: '||profile:use-cache($old-profile), 'INFO') :)
      return if ($cache-flag-changed) then
        let $create-or-destroy-cache := if (profile:use-cache($profile))
            then cache:cache-all-entries($dict)
            else cache:remove($dict)
        return ()
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
      return map {$db_name: $sort-keys}
    else if (profile:use-cache($profile)) then
      let $sort-keys := ("", map:keys(profile:get-alt-lemma-xqueries($profile))),
          $extracted-sort-values := profile:extract-sort-values($profile, ($data?current($id)?entry, $data?before($id)?entry)),
          (: $log-sort-valus := _:write-log('sort values: '||serialize($extracted-sort-values), 'INFO'), :)
          $alt-label-postfixes := $sort-keys!(if (. ne "") then '-'||. else ''),
          $changed-values := for $alt-label-postix in $alt-label-postfixes
            where $extracted-sort-values[1]/@*[local-name() = $util:vleUtilSortKey||$alt-label-postix] !=
                  $extracted-sort-values[2]/@*[local-name() = $util:vleUtilSortKey||$alt-label-postix]
            return $alt-label-postix => replace('^-', ''),
          $log-changed-values := _:write-log('changed values: '||string-join($changed-values!(if (. = '') then 'default' else .), ', '), 'INFO')
      return map {$db_name: $changed-values}
    else (), map{'duplicates': 'combine'})
  for $db_name in map:keys($changes) return cache:refresh-cache-db($dict, $db_name, distinct-values($changes($db_name)))
))
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_cache-update@after_updated',
          prof:track(
let $profile := profile:get($dict)
return if (profile:use-cache($profile))
  then if ($id = 'dictProfile')
    then cache:remove($dict)
  else cache:refresh-cache-db($dict, $db_name, ("", map:keys(profile:get-alt-lemma-xqueries($profile))))
  else map{}
))
};

declare function _:write-log($message as xs:string, $level as xs:string) as empty-sequence() {
  let $ns := replace(namespace-uri(<_:_/>), 'https://www.oeaw.ac.at/acdh/tools/vle/', '')
  return if ($_:logging-enabled) then admin:write-log($ns||':'||$message, $level) else ()
};
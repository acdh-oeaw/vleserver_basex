xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at '../api-problem.xqm';

declare function _:after_created($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_example@after_created',
          prof:track(
  file:write(file:resolve-path(string-join(('created', $dict, subsequence(map:keys($data?current), 1, 10), $db_name, distinct-values($data?current?*?status), distinct-values($data?current?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?current?*?entry)
))
};

declare function _:after_updated($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_example@after_updated',
          prof:track(
  file:write(file:resolve-path(string-join(('updated', $dict, subsequence(map:keys($data?current), 1, 10), $db_name, distinct-values($data?current?*?status), distinct-values($data?current?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?current?*?entry),
  file:write(file:resolve-path(string-join(('updated-was', $dict, subsequence(map:keys($data?before), 1, 10), $db_name, distinct-values($data?before?*?status), distinct-values($data?before?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?before?*?entry)
))
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as map(*) {
api-problem:trace-info('@plugins_example@after_deleted',
          prof:track(
  file:write(file:resolve-path(string-join(('deleted', $dict, $id, $db_name, $changingUser), '-')||'.xml', file:base-dir()), <deleted/>)
))
};
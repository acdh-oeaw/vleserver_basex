xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example';

declare function _:after_created($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('created', $dict, map:keys($data?current), $db_name, distinct-values($data?current?*?status), distinct-values($data?current?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?current?*?entry)
};

declare function _:after_updated($data as map(xs:string, map(xs:string, map(xs:string, item()?))), $dict as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('updated', $dict, map:keys($data?current), $db_name, distinct-values($data?current?*?status), distinct-values($data?current?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?current?*?entry),
  file:write(file:resolve-path(string-join(('updated-was', $dict, map:keys($data?before), $db_name, distinct-values($data?before?*?status), distinct-values($data?before?*?owner), $changingUser), '-')||'.xml', file:base-dir()), $data?before?*?entry)
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('deleted', $dict, $id, $db_name, $changingUser), '-')||'.xml', file:base-dir()), <deleted/>)
};
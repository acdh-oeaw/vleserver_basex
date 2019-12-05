xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example';

declare function _:after_created($data as element(), $dict as xs:string, $id as xs:string, $db_name as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('created', $dict, $id, $db_name, $status, $owner, $changingUser), '-')||'.xml', file:base-dir()), $data)
};

declare function _:after_updated($data-current as element(), $data-before as element(), $dict as xs:string, $id as xs:string, $db_name as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('updated', $dict, $id, $db_name, $status, $owner, $changingUser), '-')||'.xml', file:base-dir()), $data-current),
  file:write(file:resolve-path(string-join(('updated-was', $dict, $id, $db_name, $status, $owner, $changingUser), '-')||'.xml', file:base-dir()), $data-before)
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $db_name as xs:string, $changingUser as xs:string) as empty-sequence() {
  file:write(file:resolve-path(string-join(('deleted', $dict, $id, $db_name, $changingUser), '-')||'.xml', file:base-dir()), <deleted/>)
};
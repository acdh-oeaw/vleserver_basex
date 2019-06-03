xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/coordinator';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare function _:after_created($data as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
declare variable $data external; declare variable $owner external; declare variable $status external;
example:after_created($data, "`{$dict}`", "`{$id}`", $status, $owner, "`{$changingUser}`")]``, map {
            'data': $data,
            'owner': $owner,
            'status': $status
          }, 'after_created', true())
};

declare function _:after_updated($data as element(), $dict as xs:string, $id as xs:string, $status as xs:string?, $owner as xs:string?, $changingUser as xs:string) as empty-sequence() {
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
declare variable $data external; declare variable $owner external; declare variable $status external;
example:after_updated($data, "`{$dict}`", "`{$id}`", $status, $owner, "`{$changingUser}`")]``, map {
            'data': $data,
            'owner': $owner,
            'status': $status
          }, 'after_updated', true())  
};

declare function _:after_deleted($dict as xs:string, $id as xs:string, $changingUser as xs:string) as empty-sequence() {
  util:eval(``[import module namespace example = 'https://www.oeaw.ac.at/acdh/tools/vle/plugins/example' at 'plugins/example.xqm';
example:after_deleted("`{$dict}`", "`{$id}`", "`{$changingUser}`")]``, (), 'after_deleted', true())  
};
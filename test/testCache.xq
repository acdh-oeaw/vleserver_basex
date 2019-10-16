xquery version "3.0";

import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';
import module namespace ch = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../vleserver/data/cache.xqm';

for $task in ch:cache-all-entries('_qdb-TEI-02')[1]
return let $dryeds := util:eval($task/get, (), 'test-get', true())
return util:eval($task/store, map{'dryeds': $dryeds}, 'test-store', true())
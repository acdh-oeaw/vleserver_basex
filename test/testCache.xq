xquery version "3.0";

import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';
import module namespace ch = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../vleserver/data/cache.xqm';
import module namespace entr = 'https://www.oeaw.ac.at/acdh/tools/vle/entries' at '../vleserver/entries.xqm';

(: ch:cache-all-entries('_qdb-TEI-02') :)
(: ch:sort-cache-xquery('_qdb-TEI-02') :)
(: ch:sort('_qdb-TEI-02') :)
ch:refresh-cache-db('_qdb-TEI-02', 'f229_qdb-TEI-02n')
(: ch:count-all-entries('_qdb-TEI-02'), :)
(: ch:get-all-entries('_qdb-TEI-02', 200000, 25, (), 'archiv'), :)
(: util:hydrate(entr:get-dryed-from-cache('_qdb-TEI-02', (), (), 'none', (), 2000000, 25, 2428572)) :)
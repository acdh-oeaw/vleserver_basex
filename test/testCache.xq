xquery version "3.0";

import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';
import module namespace ch = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at '../vleserver/data/cache.xqm';
import module namespace da = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at '../vleserver/data/access.xqm';
import module namespace entr = 'https://www.oeaw.ac.at/acdh/tools/vle/entries' at '../vleserver/entries.xqm';

(: ch:cache-all-entries('_qdb-TEI-02') :)
ch:sort-cache-xquery('_qdb-TEI-02', ("", "archiv"))
(: ch:sort-cache-xquery2('_qdb-TEI-02') :)
(: ch:sort('_qdb-TEI-02') :)
(: ch:refresh-cache-db('_qdb-TEI-02', 'f229_qdb-TEI-02n', ("", "archiv")) :)
(: ch:count-all-entries('_qdb-TEI-02'), :)
(: ch:get-all-entries('_qdb-TEI-02', 2000000, 25, 'ascending', 'archiv', 2428572) :)
(: ch:get-entries-by-ids('_qdb-TEI-02', ("s780_qdb-d1e17103", "s780_qdb-d1e17130", "s780_qdb-d1e17153", "s780_qdb-d1e18545", "s780_qdb-d1e18572", "s780_qdb-d1e18597", "s780_qdb-d1e18624", "s780_qdb-d1e18655", "s780_qdb-d1e18683", "s780_qdb-d1e18708", "s780_qdb-d1e18736", "s780_qdb-d1e18772", "s780_qdb-d1e18795", "s780_qdb-d1e18822", "s780_qdb-d1e18847", "s780_qdb-d1e18868", "s780_qdb-d1e18888", "s780_qdb-d1e18911", "s780_qdb-d1e18936", "s780_qdb-d1e18959", "s780_qdb-d1e18984", "s780_qdb-d1e19014", "s780_qdb-d1e19039", "s780_qdb-d1e19070", "s780_qdb-d1e19099"), 1, 25, 'none', 'archiv', 25) :)
(: ch:get-entries-by-id-starting-with('_qdb-TEI-02', 's780', 1, 4137, 'none', (), 4137) :)
(: subsequence(for $d in da:get-entries-by-id-starting-with('_qdb-TEI-02', 's7')/*
order by $d/@vutlsk
return $d, 500, 25) :)
(: util:hydrate(entr:get-dryed-from-cache('_qdb-TEI-02', (), (), 'none', (), 2000000, 25, 2428572)) :)
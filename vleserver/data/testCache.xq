import module namespace da = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at 'access.xqm';
import module namespace cache = 'https://www.oeaw.ac.at/acdh/tools/vle/data/cache' at 'cache.xqm';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../util.xqm';
let $dict := '_qdb-TEI-02',
    $order := "ascending"
(: return cache:sort-cache-xquery($dict, $order, ()) :)
return cache:get-all-entries($dict, 2000000, 25, 'asc',(), cache:count-all-entries($dict))
(: return cache:get-entries-by-ids($dict, ("s761_qdb-d1e31060", "s761_qdb-d1e31192", "s761_qdb-d1e60928", "d194_qdb-d1e31234", "s764_qdb-d1e136491", "s764_qdb-d1e59313", "s764_qdb-d1e94608", "s761_qdb-d1e51509", "s761_qdb-d1e110992", "s761_qdb-d1e34656", "s761_qdb-d1e48600", "s761_qdb-d1e8506", "s761_qdb-d1e10950", "s758_qdb-d1e109126", "w862_qdb-d1e44638", "s752_qdb-d1e82200", "m578_qdb-d1e56538", "s674_qdb-d1e55922", "s674_qdb-d1e55950", "s674_qdb-d1e56468", "s752_qdb-d1e90770", "s752_qdb-d1e89756", "s731_qdb-d1e112764", "s752_qdb-d1e91905"), 1, 25, 'asc', (), 24) :)
(: return cache:get-entries-by-id-starting-with($dict, 'orig-s674', 1, 25, 'asc', (), da:count-entries-by-id-starting-with($dict, 'orig-s674')) :)
import module namespace da = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at "../vleserver/data/access.xqm";
(: da:count-all-entries('_qdb-TEI-02') :)
(: da:count-entries-by-ids('_qdb-TEI-02', ('dictProfile', 'd187_qdb-d1e16884', 'test', "s768_qdb-d1e96584")) :)
da:count-entries-by-id-starting-with('_qdb-TEI-02', 's768')
(: = count(collection('d187_qdb-TEI-02n')//*:entry) :)
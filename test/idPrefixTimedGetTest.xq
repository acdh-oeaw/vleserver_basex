import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';
import module namespace da = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at '../vleserver/data/access.xqm';
declare namespace wde = "https://www.oeaw.ac.at/acdh/tools/vle";
  let $id_start := 'w840',
      $dicts := da:get-list-of-data-dbs('_qdb-TEI-02'),
      $get-db-for-id-script := 'prof:time(('||string-join(for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[
      if (collection("`{$dict}`")//profile[starts-with(@xml:id, "`{$id_start}`") or starts-with(@ID, "`{$id_start}`")])
      then "`{$dict}`"
      else ()]``
      else ``[if (index:attributes("`{$dict}`", "`{$id_start}`")) then "`{$dict}`" else ()]``
    , ',&#x0a;')||'))',
   $ret := try {
     util:eval($get-db-for-id-script, (), 'test', false())
   } catch wde:too-many-parallel-requests { () }
return $ret
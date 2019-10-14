import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';
import module namespace da = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at '../vleserver/data/access.xqm';
declare namespace wde = "https://www.oeaw.ac.at/acdh/tools/vle";
  let $ids := ("z866_qdb-d1e4283","z866_qdb-d1e8246","z866_qdb-d1e8306","z866_qdb-d1e8363","z866_qdb-d1e21497","z866_qdb-d1e25890","z866_qdb-d1e25925","z866_qdb-d1e25960","z866_qdb-d1e44445","z866_qdb-d1e51995","z866_qdb-d1e64748","z866_qdb-d1e64803","z866_qdb-d1e73836","z866_qdb-d1e74351","z866_qdb-d1e74936","z866_qdb-d1e78972","z866_qdb-d1e79052","z866_qdb-d1e79082","z866_qdb-d1e91217","z866_qdb-d1e131952","z866_qdb-d1e133992","z866_qdb-d1e134054","z866_qdb-d1e134118","z866_qdb-d1e134181","z866_qdb-d1e142044","z866_qdb-d1e155590","h387_qdbn-d16e28211","h413_qdb-d1e71752","h420_qdb-d1e11471","h420_qdb-d1e44535","h420_qdbn-d16e62712","h420_qdbn-d16e62741","j440_qdb-d1e42180","k463_qdbn-d16e26513","k480_qdb-d1e47023","k502_qdb-d1e75547","k505_qdb-d1e4609","k505_qdb-d1e5007","k505_qdb-d1e7820","k505_qdb-d1e8103","k505_qdb-d1e9551","k505_qdb-d1e10052","k505_qdb-d1e12424","k505_qdb-d1e13006","k505_qdb-d1e13397","k505_qdb-d1e15126","k505_qdb-d1e15208","k505_qdb-d1e15353","k505_qdb-d1e15528","k505_qdb-d1e17555","k505_qdb-d1e17723","k505_qdb-d1e17767","k505_qdb-d1e17859","k505_qdb-d1e18215","k505_qdb-d1e18276","k505_qdb-d1e23157","k505_qdb-d1e23468","k505_qdb-d1e23678","k505_qdb-d1e23700","k505_qdb-d1e25693","k505_qdb-d1e25749","k505_qdb-d1e25801","k505_qdb-d1e26062","k505_qdb-d1e27466","k505_qdb-d1e27954","k505_qdb-d1e28351","k505_qdb-d1e29669","k505_qdb-d1e30414","k505_qdb-d1e31671","k505_qdb-d1e31706","k505_qdb-d1e31745","k505_qdb-d1e31989","k505_qdb-d1e32307","k505_qdb-d1e32898","k505_qdb-d1e33252","k505_qdb-d1e33545","k505_qdb-d1e33801","k505_qdb-d1e34445","k505_qdb-d1e34683","k505_qdb-d1e36066","k505_qdb-d1e36164","k505_qdb-d1e36207","k505_qdb-d1e36725"),
      $ids_seq := ``[("`{string-join($ids, '","')}`")]``,
      $dicts := da:get-list-of-data-dbs('_qdb-TEI-02'),
      $get-db-for-id-script := 'prof:time(('||string-join(for $dict in $dicts
    return if (ends-with($dict, '__prof')) then ``[
      if (collection("`{$dict}`")//profile[@xml:id = `{$ids_seq}` or @ID = `{$ids_seq}`])
      then "`{$dict}`"
      else ()]``
      else ``[if (db:attribute("`{$dict}`", `{$ids_seq}`)) then "`{$dict}`" else ()]``
    , ',&#x0a;')||'))',
   $ret := try {
     util:eval($get-db-for-id-script, (), 'test', false())
   } catch wde:too-many-parallel-requests { () }
return ($ret, $get-db-for-id-script)
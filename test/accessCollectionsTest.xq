xquery version "3.1";

import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at '../vleserver/data/access.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';

let $page := 25, $pageSize := 25,
    $nodes_or_dryed := (: data-access:get-all-entries('_qdb-TEI-02'), :) parse-xml-fragment(file:read-text('test.xml'))/*,
    $counts := $nodes_or_dryed!(if (. instance of element(util:dryed)) then xs:integer(./@count) else 1),
    $start-end-pos := for $i at $p in (1, $counts) let $start-pos := sum(($i, (1, $counts)[position() < $p]))
        return <_>
        <s>{$start-pos}</s>
        <e>{if (exists($counts[$p])) then $start-pos + $counts[$p] - 1 else 0}</e>
        <nd>{$nodes_or_dryed[$p]}</nd>
        </_>,
    $from := (($page - 1) * $pageSize) + 1, 
    $relevant_nodes_or_dryed := $start-end-pos[xs:integer(./e) >= $from and xs:integer(./s) <= $from+$pageSize],
   (: $from := 167820 2417958, $count := 10 :)   
      $entries_ids := $relevant_nodes_or_dryed/nd/*!(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/(@xml:id|@ID)
  };
]``) else ./(@xml:id|@ID)),
      $from_relevant_nodes := $from - (xs:integer($relevant_nodes_or_dryed[1]/s) - 1)
return ($from_relevant_nodes, $from, $start-end-pos[last()]/s)(: !(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/(@xml:id|@ID)
  };
]``) else ./(@xml:id|@ID)) :)
(: return util:hydrate($dryed-data, ``[
  declare function local:filter($nodes as node()*) as node()* {
    $nodes/(@xml:id|@ID)
  };
]``) :)
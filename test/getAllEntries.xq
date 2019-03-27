xquery version "3.1";

declare namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/vleserver/getAllEntries';
import module namespace vle = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at '../vleserver/data/access.xqm';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';

vle:get-all-entries('japbib_06')!(if (. instance of element(util:dryed)) then util:hydrate(., ``[
  declare function local:filter($nodes as node()*) as node()* {
    let $sorted := for $n in $nodes order by data($n/@xml:id) descending return $n
    return subsequence($sorted, 1, 25)/@xml:id
  };
]``) else ./@xml:id)
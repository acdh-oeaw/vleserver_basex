import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at 'data/access.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at "util.xqm";
import module namespace types = "https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes" at 'data/elementTypes.xqm';
(: no namespaces in profile :)
declare namespace mds = "http://www.loc.gov/mods/v3";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare function local:extractorx($node as node()) as attribute()* {};
declare function local:extractor($node as node()) as attribute()* {
  ($node/@ID,
   $node/@xml:id,
   attribute {"vutlsk"} {
     if ($node instance of element(profile)) 
     then " profile" 
     else if ($node instance of element(tei:xenoData))
     then " ignore" 
     else string-join(``[`{$node/tei:form/tei:pron}` `{$node/tei:form[@type = 'hauptlemma']/tei:orth}` `{$node/tei:form[@type = 'nebenlemma']/tei:orth}` [`{$node/tei:gramGrp/tei:pos}`]]``!normalize-space(.), ', ') },
   attribute {"vutlsk-archiv"} {
     if ($node instance of element(profile)) then " profile"
     else if ($node instance of element(tei:xenoData))
     then " ignore"
     else string-join($node//tei:ref[@type="archiv"]!normalize-space(.), ', ') }
     )
};

let $dryed as map(xs:string, item()?) := api-problem:trace-info('@cache@refresh-cache-db@l564_qdb-TEI-02n@run_query',
  prof:track(data-access:do-get-index-data(collection("l564_qdb-TEI-02n"), (), (), local:extractor#1, 0)))
return ($dryed?timings,$dryed?value)
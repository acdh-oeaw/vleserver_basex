xquery version "3.1";

declare namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/util/test-de-hydrate';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';

declare function local:extract($node as node()) as attribute()* {
  ($node/@xml:id, $node/@ID,
  attribute {"vutlsk"} {$node//*:form[1]/*:orth[1]}
  )
};

    let $dehydrated := util:dehydrate((collection("h413_qdb-TEI-02n")//*:entry, collection("d188_qdb-TEI-02n")//*:entry), local:extract#1)
(: return $dehydrated/util:d :)
return try {util:hydrate($dehydrated/util:d, ``[declare function local:filter($n) { $n/@xml:id };]``)}
catch * {
  $err:value
}
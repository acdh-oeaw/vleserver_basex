xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/profile';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';

declare variable $_:default_split_every as xs:integer := 60000;
declare variable $_:enable_trace := false();
declare variable $_:default_namespaces := (
  '(: no namespaces in profile :)',
  'declare namespace mds = "http://www.loc.gov/mods/v3";',
  'declare namespace tei = "http://www.tei-c.org/ns/1.0";'
);
declare variable $_:default_lemma_xquery := 
  "{//tei:form/tei:orth[@xml:lang='{langid}']}{//form/orth[@xml:lang='{langid}']}&#x0a;" ||
  "{//tei:cit[@type='example']/tei:quote[@xml:lang='{langid}']}{//cit[@type='example']/quote[@xml:lang='{langid}']}&#x0a;" ||
  " [{//tei:gramGrp/tei:gram[@type='pos']}{//gramGrp/gram[@type='pos']}]";

declare function _:check-contains-valid-dictname($profile as document-node()) as xs:boolean {
 if ((exists($profile/profile/tableName/@generate-db-prefix) and
      exists($profile/profile/tableName/@find-dbs)) or
      exists($profile/profile/tableName/text())) then true()
 else error(xs:QName('response-codes:_422'),
      'Profile does not contain a valid name for the data DBs',
      'Need a "<tableName>somename</tableName>" or "<tableName generate-db-prefix="somename" find-dbs="somename\d+">somename</tableName>".&#x0a;'||
      'Got "'||serialize($profile/profile/tableName, map{'method': 'xml'})||'".')
};

declare function _:get($dict_name as xs:string) as document-node() {
  util:eval(``[collection("`{$dict_name}`__prof")]``, (), 'get-profile')
};

declare function _:get-xquery-namespace-decls($profile as document-node()) as xs:string* {
  let $ret := $profile//namespaces/ns!``[declare namespace `{data(./@prefix)}` = "`{data(./@uri)}`";]``
  return if (exists($ret)) then $ret
         else $_:default_namespaces
};

(: genarates an XQuery snippet that is meant to be used with
   the concrete entry supplied as $node :)
declare function _:get-lemma-xquery($profile as document-node()) as xs:string {
  let $template := if (normalize-space($profile//displayString) ne '') then $profile//displayString/text()
        else $_:default_lemma_xquery,
      $langId := if (normalize-space($profile//mainLangLabel) ne '') then normalize-space($profile//mainLangLabel)
        else ()
  return _:template-to-template-string-transformation($template, $langId)
};

declare function _:template-to-template-string-transformation($template as xs:string, $langId as xs:string?) as xs:string {  
  let $query := $template 
        => replace('&#x0d;|&#x0a;', ''),
      $query_with_langid := if (exists($langId))
        then replace($query, '{langid}', $langId, 'iq')
        else replace($query, "\[\s*@xml:lang\s*=\s*['|&quot;]\{langid\}['|&quot;]\s*\]", '[1]', 'i'),
      $query_as_template_string := if (contains($query_with_langid, '{'))
      then '``['||$query_with_langid
        => replace('{', '`{', 'q')
        => replace('`{/', '`{$node/', 'q')
        => replace('}', '}`', 'q')||']``'
      else if (starts-with($query_with_langid, '/'))
      then $query_with_langid
        => replace('^/', '\$node/')
      else ()
  return $query_as_template_string
};

declare function _:get-alt-lemma-xqueries($profile as document-node()) as map(xs:string, xs:string) {
let $langId := if (normalize-space($profile//mainLangLabel) ne '') then normalize-space($profile//mainLangLabel)
        else ()
return map:merge((for $altDisplayString in $profile//altDisplayString
  where normalize-space($altDisplayString) ne ''
  return map{xs:string($altDisplayString/@label): _:template-to-template-string-transformation($altDisplayString, $langId)}))
};

declare function _:get-list-of-data-dbs($profile as document-node()) as xs:string* {
  let $db-regExp := data($profile/profile/tableName/@find-dbs),
      $dbs := if (exists($db-regExp)) then
        util:eval(``[db:list()[matches(., "`{$db-regExp}`")]]``, (), 'get-list-of-data-dbs')
        else $profile/profile/tableName/text()
  return $dbs
};

declare function _:get-split-every($profile as document-node()) as xs:integer {
  if ($profile/profile/tableName/@split-every) then xs:integer($profile/profile/tableName/@split-every) else $_:default_split_every
};

declare function _:get-name-for-new-db($profile as document-node(), $current-db-count as xs:integer) {
  if (exists($profile/profile/tableName/@generate-db-prefix) and
      exists($profile/profile/tableName/@find-dbs))
  then data($profile/profile/tableName/@generate-db-prefix)||format-integer($current-db-count, '000')
  else $profile/profile/tableName/text()
};

declare function _:generate-local-extractor-function($profile as document-node()) as xs:string {
let $data-extractor-xquery := _:get-lemma-xquery($profile),
    $alt-extractor-xqueries := _:get-alt-lemma-xqueries($profile)
return ``[declare function local:extractor($node as node()) as attribute()* {
  ($node/@ID, $node/@xml:id,
  attribute {"`{$util:vleUtilSortKey}`"} {string-join(`{$data-extractor-xquery}`!normalize-space(.), ', ')}`{
  if (exists($alt-extractor-xqueries?*)) then ",&#x0a;"||string-join(for $label in map:keys($alt-extractor-xqueries)
    return ``[attribute {"`{$util:vleUtilSortKey||'-'||$label}`"} {string-join(`{$alt-extractor-xqueries($label)}`!normalize-space(.), ', ')}]``, ",&#x0a;") 
    else () }` 
  )
};]``  
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};
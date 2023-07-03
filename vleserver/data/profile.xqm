xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/profile';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at '../api-problem.xqm';
import module namespace xslt = "http://basex.org/modules/xslt";

declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare namespace xsd = "http://www.w3.org/2001/XMLSchema";
declare namespace rng = "http://relaxng.org/ns/structure/1.0";
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace xsl = "http://www.w3.org/1999/XSL/Transform";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $_:default_split_every as xs:integer := 60000;
declare variable $_:enable_trace := false();
declare variable $_:sortValue := '  profile';
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

declare function _:get-rng-schema($profile as document-node()) as element(rng:grammar) {
  $profile//entrySchema/rng:grammar
};

declare function _:get-xsd-schema($profile as document-node()) as element(xsd:schema) {
  $profile//entrySchema/xsd:schema
};

declare function _:get-schematron-schema($profile as document-node()) as element(sch:schema) {
  $profile//entrySchema/sch:schema
};

declare function _:is-additional-schema-available($profile as document-node()) as xs:boolean {
    let $is-available := if (exists($profile//additionalEntrySchema/sch:schema)) then true() else false(),
    $log := _:write-log("additional schema exists: " ||$is-available,"DEBUG")
    return $is-available
};

declare function _:get-additional-schema($profile as document-node()) as element(sch:schema) {
    let $additional-schema := $profile//additionalEntrySchema/sch:schema
    return $additional-schema
};

declare function _:get-schema-type($profile as document-node()) as xs:string {
    (: let $schema := _:get($dict_name)/profile/entrySchema/*, :)
    let $schema := $profile//entrySchema/*,
        $schema_type := if ($schema instance of element(rng:grammar)) then 'rng'
        else if ($schema instance of element(xsd:schema)) then 'xsd'
        else if ($schema instance of element(sch:schema)) then 'sch'
        else (),
        $schema-is-of-valid-type := if (not(exists($schema_type))) then error(xs:QName('response-codes:_404'),'No schema for validation available','Need a relaxng grammar, a schematron schema, or a xml schema.') else ()
    return $schema_type
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
      $query_with_dict := replace($query_with_langid, "'{dict}'", '$__db__', 'q')
        => replace('\s*declare\s+variable\s+\$__db__\s+external\s*;', '','i')
        => replace('$__db__', "'{$__db__}'", 'q')
        => replace('contains\s+text\s([^\{]*)\{subQuery\}', 'contains text $1{\$noSubstQuery}')
        => replace('{subQuery}', '{$subQuery}', 'q')
        => replace('{noSubstQuery}', '{$noSubstQuery}', 'q'),
      $query_as_template_string := if (contains($query_with_dict, '{'))
      then '``['||$query_with_dict
        => replace('{', '`{', 'q')
        => replace('`{/', '`{$node/', 'q')
        => replace('}', '}`', 'q')||']``'
      else if (starts-with($query_with_dict, '/'))
      then $query_with_dict
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

declare function _:get-query-templates($profile as document-node()) as map(xs:string, xs:string) {
  let $queryTemplates := $profile//queryTemplates/queryTemplate
  return map:merge($queryTemplates!map{xs:string(./@label): xs:string(_:template-to-template-string-transformation(./text(), ''))})
};

declare function _:create-sub-query($noSubstQuery as xs:string) as xs:string {
  let $q := _:remove-wildcards($noSubstQuery)
  return switch (true()) 
    case (starts-with($noSubstQuery, '.*') or starts-with($noSubstQuery, '*')) and ends-with($noSubstQuery, '*')
      return "contains(., '"||$q||"')"
    case starts-with($noSubstQuery, '.*') or starts-with($noSubstQuery, '*')
      return "starts-with(., '"||$q||"')"
    case ends-with($noSubstQuery, '*')
      return "starts-with(., '"||$q||"')"
    default return ".='"||$q||"'"
};

declare function _:remove-wildcards($s as xs:string) as xs:string {
  replace($s, '\.?\*', '')
  =>replace("'",'&amp;apos;', 'q')
};

declare function _:create-queries-for-dbs($profile as document-node(), $noSubstQuery as xs:string, $template as xs:string, $count_only as xs:boolean) as xs:string+ {
  let $dbs as xs:string+ := _:get-list-of-data-dbs($profile),
      $template_query as xs:string := ``[declare variable $dbs as xs:string+ external;
declare variable $noSubstQuery as xs:string external;
declare variable $subQuery as xs:string external;
for $__db__ in $dbs return ]``|| $template
  return util:eval($template_query, map{'$dbs': $dbs, '$noSubstQuery': $noSubstQuery, '$subQuery': _:create-sub-query($noSubstQuery)}, 'create-queries-for-db')
};

declare function _:get-list-of-data-dbs($profile as document-node()) as xs:string* {
  let $db-regExp := data($profile/profile/tableName/@find-dbs),
      $dbs := if (exists($db-regExp)) then
        util:eval(``[db:list()[matches(., "`{$db-regExp}`")]]``, (), 'get-list-of-data-dbs')
        else $profile/profile/tableName/text()
  return $dbs
};

declare function _:get-list-of-data-dbs-and-backups($profile as document-node()) as xs:string* {
  let $db-regExp := data($profile/profile/tableName/@find-dbs),
      $dbs := if (exists($db-regExp)) then
        util:eval(``[distinct-values((db:list()[matches(., "`{$db-regExp}`")],
db:backups()/@database[matches(., "`{$db-regExp}`")]/data()))]``, (), 'get-list-of-data-dbs-and-backups')
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
  attribute {"`{$util:vleUtilSortKey}`"} {
    if ($node instance of element(profile))
    then "`{$_:sortValue}`"
    else if ($node instance of element(tei:xenoData))
    then "`{$util:ignoreSortValue}`"
    else string-join(`{$data-extractor-xquery}`!normalize-space(.), ', ')
  }`{if (exists($alt-extractor-xqueries?*)) then ",&#x0a;"||string-join(for $label in map:keys($alt-extractor-xqueries)
    return ``[attribute {"`{$util:vleUtilSortKey||'-'||$label}`"} {
    if ($node instance of element(profile))
    then "`{$_:sortValue}`"
    else if ($node instance of element(tei:xenoData))
    then "`{$util:ignoreSortValue}`"
    else string-join(`{$alt-extractor-xqueries($label)}`!normalize-space(.), ', ')
  }]``, ",&#x0a;") 
    else () }` 
  )
};]``  
};

declare function _:use-cache($profile as document-node()) as xs:boolean {
  exists($profile//useCache)
};

declare function _:extract-sort-values($profile as document-node(), $data as element()+) as element(_)+ {
let $extract-sort-values-xquery := ``[`{string-join(_:get-xquery-namespace-decls($profile), '&#x0a;')}`
             declare variable $data as element()+ external;
             `{_:generate-local-extractor-function($profile)}`
             $data!<_>{local:extractor(.)}</_>]``
return util:eval($extract-sort-values-xquery, map {'data': $data}, 'profile-extract-sort-values', true())
};

declare function _:transform-to-format($profile as document-node(), $data as element(), $format as xs:string) as xs:string {
  let $stylesheet := $profile/*/entryStyle/*[xsl:output[@method = $format]],
      $check_there_is_a_stylsheet := if (exists($stylesheet)) then true() else
      error(xs:QName('response-codes:_400'),
            $api-problem:codes_to_message(400),
            'There is no transformation for format '||$format)
  return xslt:transform-text(<tei:div type="entry">{$data}</tei:div>, $stylesheet, (), map {"cache": false()})
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};

declare %private function _:write-log($message as xs:string) {
    admin:write-log($message,"trace")
};
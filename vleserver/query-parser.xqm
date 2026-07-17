(:~
 : A parser that transforms the minimal query langauge used for searching entries into an XML tree
 :)
xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/query-parser';

import module namespace api-problem = "https://tools.ietf.org/html/rfc7807" at 'api-problem.xqm';

declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare function _:query-to-expr-tree($query as xs:string?, $valid-template-names as xs:string*) as element(fn:expr) {
  (try {
  let $terms := analyze-string($query, "[^()]+") update for $paren in ./fn:non-match return replace node $paren with util:chars($paren)!<paren>{.}</paren>,
      $termsWithLevels := _:add-level($terms/*,0)
  return <expr xmlns="http://www.w3.org/2005/xpath-functions">{_:build-tree($termsWithLevels, 0)}</expr> update 
  for $expr in .//fn:match return replace node $expr with (analyze-string($expr, "[^|&amp;]+") update
  ( ./fn:non-match[.='|']!(replace node . with <union/>),
    ./fn:non-match[.='&amp;']!(replace node . with <intersect/>),
    ./fn:match!(
    replace node . with
    (analyze-string(., "([^!=<>]+)(=|!=|>|<)(.*)")
    update (replace node ./fn:match with
    <term>{
      for $group in ./fn:match/fn:group
      return (
        switch(xs:integer($group/@nr))
        case 1 return 
          let $check_name_is_valid := if (exists($valid-template-names) and not(normalize-space($group/text()) = $valid-template-names))
              then error(xs:QName('response-codes:_400'), 
              $api-problem:codes_to_message(400),
              'There is no query template named '||$group/text()) else ()
          return <queryTemplate>{$group/text()}</queryTemplate>
        case 2 return <op>{$group/text()}</op>
        case 3 return <query>{$group/text()}</query>
        default return ()
      )      
    }</term>
  ))/*)
  ))/*
  } catch err:XUDY0027 {
    <expr xmlns="http://www.w3.org/2005/xpath-functions">{$query}</expr>
  }) update for $term at $n in .//fn:term return insert node attribute {"n"}{$n} as first into $term
};

declare function _:expr-tree-to-query($el as node()) as xs:string+ {
  _:expr-tree-to-any($el, '|', '&amp;', 
    function($el){``[(`{string-join($el/*!_:expr-tree-to-query(.), '')}`)]``},
    function($el){xs:string($el)}
  )
};

declare function _:expr-tree-to-any($el as node(), $union-string as xs:string, $intersect-string as xs:string, $expr-string as function(element(fn:expr)) as xs:string, $term-string as function(element(fn:term)) as xs:string) {  
  typeswitch($el)
    case element(fn:expr) return $expr-string($el)
    case element(fn:union) return $union-string 
    case element(fn:intersect) return $intersect-string    
    case element(fn:term) return $term-string($el)
    default return $el
};

declare %private function _:add-level($nodes as element()*, $level as xs:integer) as element()* {
  let $node := $nodes[1]
  return if ($node/text() = '(') then (<paren-open level="{$level + 1}">{$node/text()}</paren-open>,_:add-level($node/following-sibling::*, $level + 1))
  else if ($node/text() = ')') then (<paren-close level="{$level}">{$node/text()}</paren-close>,_:add-level($node/following-sibling::*, $level - 1))
  else if (exists($node)) then ($node, _:add-level($node/following-sibling::*, $level))
  else ()
};

declare %private function _:num-of-el-to-close($termsWithLevels as element()*) as xs:integer {
  let $ret := (for $e at $p in $termsWithLevels
    return if ($e[self::paren-close] and $e/@level/data() = $termsWithLevels[1]/@level/data()) then $p else ())[1]
  return if (exists($ret)) then $ret else 1
};

declare %private function _:build-tree($termsWithLevels as element()*, $level as xs:integer) {
  (if ($termsWithLevels[1][self::paren-open]) then <expr xmlns="http://www.w3.org/2005/xpath-functions">{
    _:build-tree(subsequence($termsWithLevels, 2, _:num-of-el-to-close($termsWithLevels) - 2), $level + 1)
  }</expr> else $termsWithLevels[1], if (exists(subsequence($termsWithLevels, _:num-of-el-to-close($termsWithLevels) + 1))) then _:build-tree(subsequence($termsWithLevels, _:num-of-el-to-close($termsWithLevels) + 1), $level) else ()) 
};
declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/util/test-evals";
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';

declare %unit:test function _:evals-many-queries() {
let $alphabet := ((65 to 90),(97 to 122))!codepoints-to-string(.),    
    $nodes := $alphabet!(element {.} {}),
    $queries := $alphabet!``[element {"`{.}`"}{}]``,
    $ret := util:evals($queries, (), 'evalsTestManyQueries', false())
return unit:assert-equals($ret, $nodes, 'Using many queries in evals does not work.')
};

declare %unit:test('expected', "_:error") function _:evals-many-queries-throw() {
let $queries := (1 to 52)!``[declare namespace test = "https://www.oeaw.ac.at/acdh/tools/vle/util/test-evals";
      error(xs:QName("test:error"))]``,
    $ret := util:evals($queries, (), 'evalsTestManyQueries', false())
return "will throw _:error"
};

declare %unit:test function _:evals-var-name-bindings() {
let $query := 'declare variable $n as node()* external; $n/local-name()',
    $node-names := ((65 to 90),(97 to 122))!codepoints-to-string(.),
    $nodes := $node-names!(element {.} {}),
    $bindings := map {'n': $nodes},
    $ret := util:evals($query, $bindings, 'n', 10, 'evalsTestVarNameBindings', false())
return unit:assert-equals($ret, $node-names, 'Using variable name bindings in evals does not work.')
};

declare %unit:test('expected', "err:FORG0001") function _:evals-var-name-bindings-throw() {
let $query := 'declare variable $n as node()* external; $n!xs:integer(.)',
    $node-names := ((65 to 90),(97 to 122))!codepoints-to-string(.),
    $nodes := $node-names!(element {.} {}),
    $bindings := map {'n': $nodes},
    $ret := util:evals($query, $bindings, 'n', 10, 'evalsTestVarNameBindings', false())
return "will throw FORG0001"
};

declare %unit:test function _:evals-document-bindings() {
let $query := '/*/local-name()',
    $bindings := map {'': (<a/>,<b/>,<c/>)!document{.}},
    $ret := util:evals($query, $bindings, '', 3, 'evalsTestDocumentBindings', false())
return unit:assert-equals($ret, ('a', 'b', 'c'), 'Using document bindings in evals does not work.')
};

_:evals-many-queries(), _:evals-var-name-bindings(), _:evals-document-bindings(), _:evals-var-name-bindings-throw()
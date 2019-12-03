xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/elementTypes';

declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace mds = "http://www.loc.gov/mods/v3";

declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";


declare function _:get_data_type($data as element()) as xs:string {
  typeswitch ($data)
    case element(mds:mods) return 'mods'
    case element(mds:modsCollection) return 'modsCollection'
    case element(tei:div) return 'div'
    case element(tei:entry) return 'entry'
    case element(tei:TEI) return 'TEI'
    case element(tei:teiCorpus) return 'teiCorpus'
    case element(profile) return 'profile'
    case element(tei:teiHeader) return 'header'
    case element(tei:cit) return 'example'
    case element(tei:entryFree) return 'entryFree'
    case element(tei:xenoData) return 'xenoData'
    case element(_) return '_'
    default return error(
      xs:QName('response-codes:_422'), 'Unknown data type - Unprocessable entity',
      serialize(element {
        QName($data/namespace-uri(),
          if (in-scope-prefixes($data)[1] ne "")
          then in-scope-prefixes($data)[1]||':'||$data/local-name()
          else $data/local-name()
        )} {$data/@*}
      )
    )
};

declare function _:get_data_type_of_document($data as document-node()) as xs:string {
  typeswitch ($data/*)
    case element(mds:mods) return 'mods'
    case element(mds:modsCollection) return 'modsCollection'
    case element(tei:div) return 'div'
    case element(tei:entry) return 'entry'
    case element(tei:TEI) return 'TEI'
    case element(tei:teiCorpus) return 'teiCorpus'
    case element(profile) return 'profile'
    case element(tei:header) return 'header'
    case element(tei:cit) return 'example'
    case element(tei:entryFree) return 'entryFree'
    case element(tei:xenoData) return 'xenoData'
    case element(_) return '_'
    default return error(xs:QName('response-codes:_422'), 'Unknown data type - Unprocessable entity')
};

declare function _:get-parent-node-for-element($c as document-node()*, $dataType as xs:string) as node()* {
    switch($dataType)
        case "mods" return $c/mds:modsCollection
        case "modsCollection" return $c
        case "teiCorpus" return $c
        case "TEI" return ($c/tei:teiCorpus, $c)[1]
        case "profile" return $c
        case "header" return $c/tei:TEI
        case "div" return $c/tei:TEI/tei:text/tei:body
        case "example"  return ($c/tei:TEI/tei:text/tei:body/tei:div[@type='examples'],$c/tei:TEI/tei:text/tei:body)[1]
        case "cit"  return ($c/tei:TEI/tei:text/tei:body/tei:div[@type='examples'],$c/tei:TEI/tei:text/tei:body)[1]
        case "entry"  return ($c/tei:TEI/tei:text/tei:body/tei:div[@type='entries'],$c/tei:TEI/tei:text/tei:body)[1] 
        case "entryFree"  return ($c/tei:TEI/tei:text/tei:body/tei:div[@type='entries'],$c/tei:TEI/tei:text/tei:body)[1]
        case "_" return ($c/*:_, $c)[1]
        default return $c/tei:TEI/tei:text/tei:body
};

declare function _:get_parent_node_for_change_log($e as element()) {
  typeswitch ($e)  
    case element(mds:mods) return ($e/mds:extension/*:history, $e/mds:extension)[1]
    default return $e
};

declare function _:get_all_entries($c as document-node()*) as element()* {
  ($c//tei:cit[@type = 'example'], 
   $c//tei:teiHeader,
   $c/profile,
   $c//tei:TEI,
   $c//tei:form[@type = 'lemma'],
   $c//mds:mods,
   $c//tei:entry,
   $c//tei:entryFree)[@ID or @xml:id]
};
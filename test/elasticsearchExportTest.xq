xquery version "3.1";

import module namespace esrch-plugin = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/elasticsearch-update" at "../vleserver/plugins/elasticsearch-update.xqm";
import module namespace elasicsearch-export = "https://www.oeaw.ac.at/acdh/dboe_tei_modelling/xquery/elasticsearchExport" at "../../dboe_tei_modelling/xquery/elasticsearchExport.xqm";

declare namespace _ = "urn:_";

declare function _:test($data as element()) {
(:   let $siglen := $data//*:listPlace/@corresp,
       $siglen-to-polygone := parse-json(serialize(doc('helper_json/sigle-polygone.json'), map {'method': 'json'})),
      $json-as-xquery-maps := map:merge((
        elasicsearch-export:get-sigle-polygone($siglen, $siglen-to-polygone)
      ))      
  return serialize($json-as-xquery-maps, map {"method": "json", "indent": "no"}) :)
  try { esrch-plugin:sendToElasticasearch((esrch-plugin:createNDJsonDataHeader($data/@xml:id), esrch-plugin:createNDJsonDataBody($data)))
   (:  esrch-plugin:after_updated($data, 'some_dict', $data/@xml:id, (), (), 'auser') :)
  }
  catch experr:* {$err:additional}
};
<entry xmlns="http://www.tei-c.org/ns/1.0" xml:id="f277_qdb-d1e86190" n="317184" source="#orig-f277_qdb-d1e86190">
  <form type="hauptlemma" xml:id="tu-49948.42">
    <orth>Fotze</orth>
  </form>
  <gramGrp>
    <pos>Subst</pos>
  </gramGrp>
  <form type="lautung" n="1" xml:id="tu-49948.46">
    <pron xml:lang="bar" notation="teuthonista">fouz</pron>
  </form>
  <sense corresp="this:LT1" xml:id="tu-49948.47">
    <def xml:lang="de">vulva</def>
  </sense>
  <ref type="archiv" xml:id="tu-49948.41">HK 277, F277#3066.1 = F2770724.eck#9.1, korr. I.G.</ref>
  <ref type="quelle" xml:id="tu-49948.43">Kostiál St.(1910)<ref type="seite">31</ref>
  </ref>
  <ref type="quelleBearbeitet" xml:id="tu-49948.44">{3.2} mbair.ObSt.:St. </ref>
  <ref type="bibl" corresp="this:QDB">
    <bibl>KOsTIÁL· (1910) S. [S-5077: erot.Id.] ** Exz.Narovnigg/Ernst</bibl>
  </ref>
  <usg type="geo" corresp="this:QDB">
    <placeName type="orig">Umg.v. Bruck, Frohnltn., Mixnitz in Gm. Pernegg, Graz u. Ilzt. St.</placeName>
    <listPlace corresp="sigle:3.2a01">
      <place type="Bundesland">
        <placeName>Stmk.</placeName>
        <idno>3</idno>
        <listPlace>
          <place type="Großregion">
            <placeName>mbair.ObStmk.</placeName>
            <idno>3.2</idno>
            <listPlace>
              <place type="Kleinregion">
                <placeName>östl.obMurt.</placeName>
                <idno>3.2a</idno>
                <listPlace>
                  <place type="Gemeinde">
                    <placeName>Bruck an der Mur</placeName>
                    <listPlace>
                      <place type="Ort">
                        <placeName>Bruck an der Mur</placeName>
                        <idno>3.2a01</idno>
                      </place>
                    </listPlace>
                  </place>
                </listPlace>
              </place>
            </listPlace>
          </place>
        </listPlace>
      </place>
    </listPlace>
    <listPlace corresp="sigle:3.4a04">
      <place type="Bundesland">
        <placeName>Stmk.</placeName>
        <idno>3</idno>
        <listPlace>
          <place type="Großregion">
            <placeName>MStmk.</placeName>
            <idno>3.4</idno>
            <listPlace>
              <place type="Kleinregion">
                <placeName>nMStmk.</placeName>
                <idno>3.4a</idno>
                <listPlace>
                  <place type="Gemeinde">
                    <placeName>Frohnleiten</placeName>
                    <listPlace>
                      <place type="Ort">
                        <placeName>Frohnleiten</placeName>
                        <idno>3.4a04</idno>
                      </place>
                    </listPlace>
                  </place>
                </listPlace>
              </place>
            </listPlace>
          </place>
        </listPlace>
      </place>
    </listPlace>
    <listPlace corresp="sigle:3.4a11">
      <place type="Bundesland">
        <placeName>Stmk.</placeName>
        <idno>3</idno>
        <listPlace>
          <place type="Großregion">
            <placeName>MStmk.</placeName>
            <idno>3.4</idno>
            <listPlace>
              <place type="Kleinregion">
                <placeName>nMStmk.</placeName>
                <idno>3.4a</idno>
                <listPlace>
                  <place type="Gemeinde">
                    <placeName>Pernegg an der Mur</placeName>
                    <listPlace>
                      <place type="Ort">
                        <placeName>Pernegg an der Mur</placeName>
                        <idno>3.4a11</idno>
                      </place>
                    </listPlace>
                  </place>
                </listPlace>
              </place>
            </listPlace>
          </place>
        </listPlace>
      </place>
    </listPlace>
    <listPlace corresp="sigle:3.4d01">
      <place type="Bundesland">
        <placeName>Stmk.</placeName>
        <idno>3</idno>
        <listPlace>
          <place type="Großregion">
            <placeName>MStmk.</placeName>
            <idno>3.4</idno>
            <listPlace>
              <place type="Kleinregion">
                <placeName>Graz</placeName>
                <listPlace>
                  <place type="Gemeinde">
                    <placeName>Graz</placeName>
                    <listPlace>
                      <place type="Ort">
                        <placeName>Graz</placeName>
                        <idno>3.4d01</idno>
                      </place>
                    </listPlace>
                  </place>
                </listPlace>
              </place>
            </listPlace>
          </place>
        </listPlace>
      </place>
    </listPlace>
    <listPlace corresp="sigle:3.5g12">
      <place type="Bundesland">
        <placeName>Stmk.</placeName>
        <idno>3</idno>
        <listPlace>
          <place type="Großregion">
            <placeName>OStmk.</placeName>
            <idno>3.5</idno>
            <listPlace>
              <place type="Kleinregion">
                <placeName>uFeistritzt.</placeName>
                <idno>3.5g</idno>
                <listPlace>
                  <place type="Gemeinde">
                    <placeName>Ilztal</placeName>
                    <listPlace>
                      <place type="Ort">
                        <placeName>Ilztal</placeName>
                        <idno>3.5g12</idno>
                      </place>
                    </listPlace>
                  </place>
                </listPlace>
              </place>
            </listPlace>
          </place>
        </listPlace>
      </place>
    </listPlace>
  </usg>
</entry>!_:test(.)
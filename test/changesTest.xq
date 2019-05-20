xquery version "3.0";

import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';
import module namespace chg = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at '../vleserver/data/changes.xqm';
<test xmlns="http://www.tei-c.org/ns/1.0">
<fs type='change'><f name="owner"><symbol value='changTestUser'/></f></fs>
</test> transform with {chg:add-change-record(., <fs type='change' xml:space="preserve"><f name="who"><symbol value="test"/></f><f name="when"><symbol value="2019_05_15 11:34"/></f></fs>, "released", (), "changTestUser")},
<mods xmlns="http://www.loc.gov/mods/v3">
<fs type='change'><f name="who"><symbol value="test"/></f><f name="when"><symbol value="2019_05_15 11:34"/></f><f name="status"><symbol value='released'/></f></fs>
  <extension>
    <_:history xmlns:_="urn:_" xmlns="http://www.tei-c.org/ns/1.0" xml:space="preserve">
    </_:history>
  </extension>
</mods> transform with {chg:add-change-record(., .//*:fs transform with {delete node .//*:f[@name="status"]}, (), "someUser", "changTestUser")},
<profile when="2019-05-15T19:09:29"/> transform with {chg:add-change-record-to-profile(.)}

(: util:eval(``[import module namespace acc = 'https://www.oeaw.ac.at/acdh/tools/vle/data/access' at 'data/access.xqm';
import module namespace chg = 'https://www.oeaw.ac.at/acdh/tools/vle/data/changes' at 'data/changes.xqm';
 chg:save-entry-in-history("test", <test></test>)]``
  , (), 'changes-test', true()) :)
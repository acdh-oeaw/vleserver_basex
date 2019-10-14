xquery version "3.1";

declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access/test-getLemmaXPath";
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at '../vleserver/data/profile.xqm';

profile:get('japbib_06')/profile/lemmaXPath
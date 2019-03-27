xquery version "3.1";

declare namespace _ = "https://www.oeaw.ac.at/acdh/tools/vle/data/access/test-getLemmaXPath";
import module namespace data-access = "https://www.oeaw.ac.at/acdh/tools/vle/data/access" at '../vleserver/data/access.xqm';

data-access:get-profile('japbib_06')/profile/lemmaXPath
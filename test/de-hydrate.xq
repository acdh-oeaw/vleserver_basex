xquery version "3.1";

declare namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/util/test-de-hydrate';
import module namespace util = 'https://www.oeaw.ac.at/acdh/tools/vle/util' at '../vleserver/util.xqm';

util:hydrate(util:dehydrate(collection('japbib_06')//*:mods))
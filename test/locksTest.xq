xquery version "3.0";

import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../vleserver/util.xqm';
import module namespace lck = 'https://www.oeaw.ac.at/acdh/tools/vle/data/locks' at '../vleserver/data/locks.xqm';

declare variable $test := format-dateTime(current-dateTime() + xs:dayTimeDuration('PT300S'),'[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]');

document {<locks>
  <lock id="id_112" user="charly" dt="2018-09-11T14:28:58"/>
  <lock id="saamah_001" user="charly" dt="2018-09-11T15:06:39"/>
  <lock id="id_2282" user="charly" dt="2018-09-12T18:18:27"/>
</locks> } transform with {lck:_remove_expired_locks(.)},

document {<locks>
  <lock id="id_112" user="charly" dt="2018-09-11T14:28:58"/>
  <lock id="saamah_001" user="charly" dt="2018-09-11T15:06:39"/>
  <lock id="id_2282" user="charly" dt="2018-09-12T18:18:27"/>
</locks> } transform with {lck:_lock_entry(., 'testUser', 'someID', $test)},

(document {<locks>
  <lock id="id_112" user="charly" dt="2018-09-11T14:28:58"/>
  <lock id="saamah_001" user="charly" dt="2018-09-11T15:06:39"/>
  <lock id="id_2282" user="charly" dt="2018-09-12T18:18:27"/>
</locks> } transform with {lck:_lock_entry(., 'testUser', 'someID', $test)})
transform with {lck:_remove_expired_locks(.)},
lck:get_user_locking_entry('enimmollitirure', 'test_01')
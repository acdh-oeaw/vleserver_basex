xquery version "3.1";

import module namespace esrch-plugin = "https://www.oeaw.ac.at/acdh/tools/vle/plugins/elasticsearch-update" at "../vleserver/plugins/elasticsearch-update.xqm";

declare namespace _ = 'urn:_';

esrch-plugin:write-log((<http:response xmlns:http="http://expath.org/ns/http-client" status="404" message="Not Found">
  <http:header name="Keep-Alive" value="timeout=5, max=100"/>
  <http:header name="Server" value="Apache/2.4.6 (CentOS) OpenSSL/1.0.2k-fips"/>
  <http:header name="Connection" value="Keep-Alive"/>
  <http:header name="Content-Length" value="198"/>
  <http:header name="Date" value="Mon, 27 May 2019 15:09:23 GMT"/>
  <http:header name="Content-Type" value="text/html; charset=iso-8859-1"/>
  <http:body media-type="text/html"/>
</http:response>,
<html>
  <head>
    <title>404 Not Found</title>
  </head>
  <body>
    <h1>Not Found</h1>
    <p>The requested URL / was not found on this server.</p>
  </body>
</html>)),
esrch-plugin:write-log((<http:response xmlns:http="http://expath.org/ns/http-client" status="200" message="OK">
  <http:header name="content-length" value="234"/>
  <http:header name="Warning" value="299 Elasticsearch-7.0.0-b7e28a7 &quot;[types removal] Specifying types in bulk requests is deprecated.&quot;"/>
  <http:header name="content-type" value="application/json; charset=UTF-8"/>
  <http:body media-type="application/json"/>
</http:response>,
<json type="object">
  <took type="number">66</took>
  <errors type="boolean">false</errors>
  <items type="array">
    <_ type="object">
      <index type="object">
        <__index>dboe</__index>
        <__type>_doc</__type>
        <__id>f277_qdb-d1e86190</__id>
        <__version type="number">3</__version>
        <result>updated</result>
        <__shards type="object">
          <total type="number">2</total>
          <successful type="number">1</successful>
          <failed type="number">0</failed>
        </__shards>
        <__seq__no type="number">2625757</__seq__no>
        <__primary__term type="number">6</__primary__term>
        <status type="number">200</status>
      </index>
    </_>
  </items>
</json>)),
esrch-plugin:write-log((<http:response xmlns:http="http://expath.org/ns/http-client" status="404" message="Not Found">
  <http:header name="Server" value="Jetty(9.4.18.v20190429)"/>
  <http:header name="Content-Length" value="43"/>
  <http:header name="Date" value="Mon, 27 May 2019 14:59:45 GMT"/>
  <http:header name="Content-Type" value="text/plain;charset=utf-8"/>
  <http:body media-type="text/plain"/>
</http:response>,
'No function found that matches the request.')),
esrch-plugin:write-log((<http:response xmlns:http="http://expath.org/ns/http-client" status="405" message="Method Not Allowed">
  <http:header name="content-length" value="117"/>
  <http:header name="content-type" value="application/json; charset=UTF-8"/>
  <http:header name="Allow" value="GET,HEAD,DELETE,PUT"/>
  <http:body media-type="application/json"/>
</http:response>,
<json type="object">
  <error>Incorrect HTTP method for uri [/_bulkx] and method [POST], allowed: [GET, HEAD, DELETE, PUT]</error>
  <status type="number">405</status>
</json>))

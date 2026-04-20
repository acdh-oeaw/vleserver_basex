let $dict_name := "dc_shawi_eng"
return http:send-request(<http:request method="get"/>, "http://localhost:8984/restvle/dicts/"||$dict_name)[2]
  /json/__embedded/__/_/specialCharacters
  update { for $_ in .//_ return replace node $_ with <char>{$_/*}</char>, delete node ./@type }
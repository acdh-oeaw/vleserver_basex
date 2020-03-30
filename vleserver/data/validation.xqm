xquery version "3.1";

module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/validation';
import module namespace util = "https://www.oeaw.ac.at/acdh/tools/vle/util" at '../util.xqm';
import module namespace profile = "https://www.oeaw.ac.at/acdh/tools/vle/data/profile" at 'profile.xqm';

declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";

declare variable $_:enable_trace := false();

declare function _:xml($profile as document-node(), $entry as document-node()) {
  let $schema_type := if (exists($profile//entrySchema)) then profile:get-schema-type($profile) else ()
        (: $log := _:write-log("value of entry/profile " || $entry/profile), :)
        (: $log := _:write-log("value of entry " || serialize($entry)), :)
        (: $log := _:write-log(serialize(profile:get-schema($dict_name))), :)
  return (if(exists($schema_type)) then try {
            switch($schema_type)
                case 'rng' return validate:rng($entry,profile:get-rng-schema($profile))
                case 'xsd' return validate:xsd($entry,profile:get-xsd-schema($profile))
                case 'sch' return _:validate-with-schematron-schema($entry, profile:get-schematron-schema($profile),"basic")
                default return ()
        } catch validate:init {
            error(xs:QName('response-codes:_422'),'Error during validation', 'The validation cannot be started.'||
                'XML was: '||serialize($entry, map{'method': 'xml', 'indent': 'yes'})||'&#x0a;'||
                $err:additional)
        } catch validate:not-found {
            error(xs:QName('response-codes:_422'),'Error during validation','No validator is available.'||
                'XML was: '||serialize($entry, map{'method': 'xml', 'indent': 'yes'})||'&#x0a;'||
                $err:additional)
        (: } catch validate:version {
            error(xs:QName('response-codes:_422'),'Error during validation','No validator is found for the specified version. '||
                'XML was: '||$userData/json/entry/text()||'&#x0a;'||
                $err:additional) :)
        } catch validate:error {
            let $error := error(xs:QName('response-codes:_422'),'Error during validation',
                'The document cannot be validated against the specified schema. '||
                'XML was: '||serialize($entry, map{'method': 'xml', 'indent': 'yes'})||'&#x0a;'||
                $err:additional||'&#x0a;')
            return $entry/*
        } else (),
        if (profile:is-additional-schema-available($profile))
                then try {
                    _:validate-with-schematron-schema($entry,profile:get-additional-schema($profile),"additional")
                } catch * {
                    let $error := error(xs:QName('response-codes:_422'),'Error during additional validation '||$err:additional,'Unknown error during additional validation.')
                    return ()
                }
                (: else _:write-log('No additional schema available - skipping additional validation.','DEBUG') :)
                else ()
       )
};

declare %private function _:validate-with-schematron-schema($entry as document-node(),$schema as element(),$type as xs:string){
    try {
        util:eval(``[import module namespace schematron = 'http://github.com/Schematron/schematron-basex';
        import module namespace _ = 'https://www.oeaw.ac.at/acdh/tools/vle/data/validation' at 'data/validation.xqm';
        declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
        declare variable $entry  as document-node() external;
        declare variable $schema as element(sch:schema) external;
        let $compiled-schema := schematron:compile($schema),
        $message := schematron:validate($entry,$compiled-schema),
        $validation-result := if (schematron:is-valid($message)) then () else _:create-error-message-for-failed-schematron-validation($message,"`{$type}`")
        return ()]``,map{'entry':$entry,'schema':$schema},'validate-with-schematron-schema',true())
    } catch err:XQST0059 {
        error(xs:QName('response-codes:_503'),'Could not find library module for schematron validation.',
        'Please install http://github.com/Schematron/schematron-basex with repo:install("https://github.com/Schematron/schematron-basex/raw/master/dist/schematron-basex-1.2.xar").')
    }
};

declare function _:create-error-message-for-failed-schematron-validation($validation-result,$type as xs:string) {
    util:eval(``[import module namespace schematron = 'http://github.com/Schematron/schematron-basex';
    declare namespace response-codes = "https://tools.ietf.org/html/rfc7231#section-6";
    declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
    declare variable $validation-result as document-node(element(svrl:schematron-output)) external;
    let $error-message := for $message in schematron:messages($validation-result)
        return concat(schematron:message-level($message), ': ',schematron:message-description($message)),
    $error := error(xs:QName('response-codes:_422'),'Error during ' || "`{$type}`" || ' validation ',
    'Error message:'||'&#x0a;'||$error-message)
    return ()]``,map{'validation-result':$validation-result},'create-error-message-for-failed-schematron-validation',true())
};

declare %private function _:write-log($message as xs:string, $severity as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, $severity) else ()
};

declare %private function _:write-log($message as xs:string) {
  if ($_:enable_trace) then admin:write-log($message, "TRACE") else ()
};
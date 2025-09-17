<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:_="urn:_"
    version="4.0">
    
    <xd:doc>
      <xd:desc>This is a naive reimplementation of the algorithm BaseX uses to serialize its XML JSON representation.
          Used for testing the transformation of whole dictionaries into JSON.
          Missing features include the declaration of JSON value types on the root json element and
          handling of more types than string, object and array.
      </xd:desc>  
    </xd:doc>
    <xsl:output method="json" indent="true"/>
    
    <xd:doc>
        <xd:desc>Instead of specifying a type, objects can be listed in an attribute on the json root element</xd:desc>
    </xd:doc>
    <xsl:variable name="objects" select="tokenize(json/@objects/data())"/>    
    <xd:doc>
        <xd:desc>Instead of specifying a type, arrays/ can be listed in an attribute on the json root element</xd:desc>
    </xd:doc>
    <xsl:variable name="arrays" select="tokenize(json/@arrays/data())"/>    
    <xd:doc>
        <xd:desc>Instead of specifying a type, strings can be listed in an attribute on the json root element</xd:desc>
    </xd:doc>
    <xsl:variable name="strings" select="tokenize(json/@strings/data())"/>
    
    <xd:doc>
        <xd:desc>Process the marker element or an array element if it is marked as an object.</xd:desc>
    </xd:doc>
    <xsl:template match="(json|_)[@type='object' or  local-name() = $objects]" priority="2"> 
        <xsl:map>
            <xsl:apply-templates select="*"/>
        </xsl:map>       
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Hard coded key name decoder. Decodes only $ and @.
            This actually references unicode codepoints.</xd:desc>
        <xd:param name="in">The key name to be decoded.</xd:param>
    </xd:doc>
    <xsl:function name="_:decode-json-key" as="xs:string">
        <xsl:param name="in" as="xs:string"/>
        <xsl:value-of select="
            replace($in, '_0024', '$', 'q') =>
            replace('_0040', '@', 'q') =>
            replace('__', '_', 'q')"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Straight forward handling of JSON objects as XSL maps.</xd:desc>
    </xd:doc>    
    <xsl:template match="*[@type='object' or local-name() = $objects]">
        <xsl:map-entry key="_:decode-json-key(local-name())"><xsl:map><xsl:apply-templates select="*[@type=('object', 'array') or not(@type)]"/></xsl:map></xsl:map-entry>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A handling similar to maps for arrays is probosed for XSL 4.0. At the moment this should handle array values.</xd:desc>
    </xd:doc>
    <xsl:template match="*[@type='array' or local-name() = $arrays]">
        <xsl:variable name="object_contents" as="map(*)*">
            <xsl:apply-templates select="_[@type='object']"/>
        </xsl:variable>
        <xsl:variable name="array_contents" as="array(*)*">
            <xsl:apply-templates select="_[@type='array']"/>
        </xsl:variable>
        <xsl:variable name="string_contents" as="xs:string*">
            <xsl:apply-templates select="_[not(@type)]"/>
        </xsl:variable>
        <xsl:map-entry key="_:decode-json-key(local-name())" select="array{($object_contents, $array_contents, $string_contents)}"/> 
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The default transformation for element: content is key: xs:string(value).</xd:desc>
    </xd:doc>
    <xsl:template match="*[not(@type) or @type='string' or local-name() = $strings]">
        <xsl:map-entry key="_:decode-json-key(local-name())"><xsl:sequence select="xs:string(.)"/></xsl:map-entry>
    </xsl:template>
    
</xsl:stylesheet>
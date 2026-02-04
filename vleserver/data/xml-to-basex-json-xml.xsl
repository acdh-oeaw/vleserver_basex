<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    exclude-result-prefixes="xs math xd tei"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 28, 2025</xd:p>
            <xd:p><xd:b>Author:</xd:b>Omar Siam</xd:p>
            <xd:p>This stylesheet transrorms any XML to the XML representation
                of JSON that BaseX uses. The representation contains all information
                in the original XML and is with a few notable exceptions reversible.
                This stylesheeet can work on its own but if you have special needs for chnaging how
                XML elemnts are processed you should be able to import and override the behavior.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>The following elements have a special use and need to be ignored.
            This is meant to be customized in stylesheets that import this one.
        </xd:desc>
        <xd:param name="element">One or more elements. The first one is checked if it matches the ignore list.</xd:param>
    </xd:doc>
    <xsl:function name="tei:is-ignored-element" as="xs:boolean">
        <xsl:param name="element" as="node()+"/>
        <xsl:sequence select="exists($element/(self::*:dict, self::tei:standOff))"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>The following elements have a special use and need to be processd differently.
            This function selects elements for processing without automatically generating an object or array
            from the elements local-name().
            This is meant to be customized in stylesheets that import this one.
        </xd:desc>
        <xd:param name="element">One or more elements. The first one is checked if it matches the list of special elements that should not be transformed automatically to an array or object.</xd:param>
    </xd:doc>
    <xsl:function name="tei:is-special-element" as="xs:boolean">
        <xsl:param name="element" as="node()+"/>
        <xsl:sequence select="exists($element/(self::tei:ref,self::tei:fs,self::tei:gram[@type='construction'],self::tei:*[starts-with(local-name(), 'list')]))"/>
    </xsl:function>  

    <xd:doc>
        <xd:desc>Hard coded key name encoder. Encodes only $ and @.
            This actually references unicode codepoints.</xd:desc>
        <xd:param name="in">The key name to be decoded.</xd:param>
    </xd:doc>
    <xsl:function name="tei:encode-json-key" as="xs:string">
        <xsl:param name="in" as="xs:string"/>
        <xsl:value-of select="
            replace($in, '$', '_0024', 'q') =>
            replace('@', '_0040', 'q') =>
            replace('_', '__', 'q')"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>Returns a JSON name that follows the pattern @type_local-name().
            @type is optional.
        </xd:desc>
        <xd:param name="element">One or more element of the same (TEI) kind.</xd:param>
    </xd:doc>
    <xsl:function name="tei:get-typed-element-name" as="xs:string">
        <xsl:param name="element" as="node()+"/>
        <xsl:variable name="typed-element-name">
            <xsl:choose>
                <xsl:when test="tei:is-special-element($element[1])">
                    <xsl:value-of select="$element[1]/local-name()"/>
                </xsl:when>
                <xsl:when test="count($element) > 1">
                    <xsl:variable name="plural_ending" as="xs:string">
                        <xsl:choose>
                            <xsl:when test="ends-with($element[1]/local-name(), 'y')">ies</xsl:when>
                            <xsl:otherwise><xsl:value-of select="substring($element[1]/local-name(), string-length($element[1]/local-name()), 1)||'s'"/></xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:value-of select="string-join((data($element[1]/@type), substring($element[1]/local-name(), 1, string-length($element[1]/local-name()) - 1)), '_')||$plural_ending"/>
                </xsl:when>
                <xsl:otherwise>               
                    <xsl:value-of select="string-join((data($element[1]/@type), $element[1]/local-name()), '_')"/> 
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="tei:encode-json-key($typed-element-name)"/>
    </xsl:function>
    
    <xd:doc>
        <xd:desc>The root element of BaseX'es JSON representation is json</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <json type="object">
            <xsl:apply-templates mode="named-object"/>
        </json>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Group all elements with the same local-name together.
            Process multiple elements with a name as array.
        </xd:desc>
    </xd:doc>
    <xsl:template match="*">
        <xsl:apply-templates select="@*"/>
        <xsl:call-template name="group-xml-elements"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Group all elements with the same local-name together.
            Process multiple elements with a name as array.
        </xd:desc>
    </xd:doc>
    <xsl:template match="*" mode="named-object">
        <xsl:element name="{tei:encode-json-key(local-name())}">
            <xsl:attribute name="type">object</xsl:attribute>
            <xsl:apply-templates select="@*" mode="#default"/>
            <xsl:call-template name="group-xml-elements"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This handles the generation of JSON keys from XML elements.</xd:desc>
    </xd:doc>
    <xsl:template name="group-xml-elements">
        <xsl:for-each-group select="*|text()[normalize-space(.) ne '']" group-adjacent="tei:get-typed-element-name(.)">
            <xsl:call-template name="element-number-processing-switch">
                <xsl:with-param name="element-group" select="current-group()"/>
            </xsl:call-template>
        </xsl:for-each-group>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This changes processing in different ways depending on the number if elements passed in a group.</xd:desc>
        <xd:param name="element-group">A group of elements. Most probably current-group() from for-each-group.</xd:param>
    </xd:doc>
    <xsl:template name="element-number-processing-switch">
        <xsl:param name="element-group"/>
        <xsl:choose>
            <xsl:when test="tei:is-ignored-element($element-group)"/>
            <xsl:when test="tei:is-special-element($element-group) and count($element-group) = 1">
                <xsl:apply-templates select="$element-group" mode="#current"/>  
            </xsl:when>
            <xsl:when test="tei:is-special-element($element-group) and count($element-group) > 1"> 
               <xsl:apply-templates select="$element-group" mode="array"/>
            </xsl:when>
            <xsl:when test="$element-group/local-name() = ''">
                <xsl:apply-templates select="$element-group" mode="#current"/> 
            </xsl:when>
            <xsl:when test="count($element-group) > 1">
                <xsl:variable name="content">
                    <xsl:apply-templates select="$element-group" mode="array"/>                       
                </xsl:variable>
                <xsl:if test="exists($content/(*|text()))">
                    <xsl:element name="{tei:get-typed-element-name($element-group)}">
                        <xsl:attribute name="type">array</xsl:attribute>
                        <!-- this is the same as $content, but it is easier to debug in oxygenXML like this -->
                        <xsl:apply-templates select="$element-group" mode="array"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="content">
                    <xsl:apply-templates select="$element-group" mode="#default"/>                    
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="exists($content/(@*|*|text()))">
                        <xsl:element name="{tei:get-typed-element-name($element-group)}">
                            <xsl:attribute name="type">object</xsl:attribute>
                            <!-- this is the same as $content, but it is easier to debug in oxygenXML like this -->
                            <xsl:apply-templates select="$element-group" mode="#default"/>
                        </xsl:element>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:element name="{tei:get-typed-element-name($element-group)}"/>    
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Multiple elements are processed as arrays.
            Array elements in the BaseX JSON representation are enclosed in _ tags.</xd:desc>
    </xd:doc>   
    <xsl:template match="*" mode="array">
        <_ type="object">
            <xsl:apply-templates select="@*"/>
            <xsl:call-template name="group-xml-elements"/>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Handling of multiple text nodes or mixed content as an array.</xd:desc>
    </xd:doc>   
    <xsl:template match="*" mode="sequence">
        <xsl:for-each-group select="@*|*|text()[normalize-space(.) ne '']" group-adjacent="tei:get-typed-element-name(.)">
            <xsl:choose>
                <xsl:when test="tei:is-ignored-element(current-group())"/>
                <xsl:when test="tei:is-special-element(current-group())">
                    <xsl:call-template name="element-number-processing-switch">
                        <xsl:with-param name="element-group" select="current-group()"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:when test="current-group() instance of attribute()">
                    <_ type="object">
                        <xsl:apply-templates select="." mode="#default"/>
                    </_>
                </xsl:when>
                <xsl:otherwise>
                    <_ type="object">
                        <xsl:call-template name="element-number-processing-switch">
                            <xsl:with-param name="element-group" select="current-group()"/>
                        </xsl:call-template>
                    </_>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each-group>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Multiple text nodes are transformed to a key '$$' and an array value.
            These text nodes can be mixed with elements.</xd:desc>
    </xd:doc>   
    <xsl:template match="*[normalize-space(string-join(text())) ne '' and count(text()) > 1]" mode="#default">        
        <xsl:apply-templates select="@*"/>
        <_0024_0024 type="array">
            <xsl:attribute name="type">array</xsl:attribute>
            <xsl:apply-templates select="." mode="sequence"/>
        </_0024_0024>        
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Multiple text nodes are transformed to a key '$$' and an array value.
            These text nodes can be mixed with elements.
            Array mode.
        </xd:desc>
    </xd:doc>   
    <xsl:template match="*[normalize-space(string-join(text())) ne '' and count(text()) > 1]" mode="array">
        <_ type="object">
            <xsl:apply-templates select="@*"/>
            <_0024_0024 type="array">
                <xsl:attribute name="type">array</xsl:attribute>
                <xsl:apply-templates select="." mode="sequence"/>
            </_0024_0024>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Attributes are transformed to keys with an @ prepended.</xd:desc>
    </xd:doc>   
    <xsl:template match="@*">
        <xsl:element name="{'_0040'||local-name()}"><xsl:value-of select="."/></xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Text nodes are transformed to a key '$'.</xd:desc>
    </xd:doc>   
    <xsl:template match="text()" mode="#default array sequence">
        <_0024><xsl:value-of select="normalize-space(.)"/></_0024>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>TEI feature structures are key value representations.
            Transforming them directly to JSON objects seems to be the best way of dealing with them.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs" mode="#default">
        <feature type="object">
            <xsl:apply-templates mode="tei-fs"/>
        </feature>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>TEI feature structures are key value representations.
            This is the variant for multiple feature structures at the same XML level.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs[@type]" mode="sequence">
        <_ type="object">
            <xsl:element name="{tei:encode-json-key(@type)}">
                <xsl:attribute name="type">object</xsl:attribute>
                <xsl:apply-templates mode="tei-fs"/>
            </xsl:element>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>TEI feature structures are key value representations.
            This is the variant for multiple feature structures at the same XML level.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs[@type][position() = 1]" mode="array">
        <features type="array">
            <xsl:for-each select="(., following-sibling::tei:fs[@type])">
                <_ type="object">
                    <xsl:element name="{tei:encode-json-key(@type)}">
                        <xsl:attribute name="type">object</xsl:attribute>
                        <xsl:apply-templates mode="tei-fs"/>
                    </xsl:element>
                </_>
            </xsl:for-each>
        </features>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>As the whole group is processed with the first element ignore all others</xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs[@type][position() > 1]" mode="array"/>
    
    <xd:doc>
        <xd:desc>Second possible form to represend a key value pair</xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs" mode="array sequence">
        <_ type="object">
            <xsl:apply-templates mode="tei-fs"/>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Key and value in a feature are modeled using attributes and two elements.
            Transform them to simply "key": "value" pairs. 
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:f" mode="tei-fs">
        <xsl:element name="{tei:encode-json-key(@name)}">
            <xsl:value-of select="(tei:symbol/@value, text())[1]"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Text nodes on feature structures generally do not convey any information.
            Ignore text nodes in TEI feature structures.
        </xd:desc>
    </xd:doc>
    <xsl:template match="text()" mode="tei-fs"/>
    
    <xd:doc>
        <xd:desc>list* elements are by definition best represented as arrays</xd:desc>
    </xd:doc>
    <xsl:template match="tei:*[starts-with(local-name(), 'list')]">
        <xsl:element name="{tei:encode-json-key(local-name())}">
            <xsl:attribute name="type">array</xsl:attribute>
            <xsl:apply-templates mode="array" select="*"/>
        </xsl:element>
    </xsl:template>

    <xd:doc>
        <xd:desc>list* elements are by definition best represented as arrays
            In an array or sequence context declare them as objects.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:*[starts-with(local-name(), 'list')]" mode="array sequence">
        <_ type="object">
            <xsl:element name="{tei:encode-json-key(local-name())}">
                <xsl:attribute name="type">array</xsl:attribute>
                <xsl:apply-templates mode="array" select="*"/>
            </xsl:element>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>tei:ref is marked as a special tag but this stylesheet can not know how to resolve refs.
            So treat them like the automatic conversion as default.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:ref">
        <ref type="object">
            <xsl:apply-templates select="@*|*|text()"/>
        </ref>
    </xsl:template>
</xsl:stylesheet>
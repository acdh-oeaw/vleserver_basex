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
            in the original XML and is with a few notable exceptions reversible.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>The following elements have a special use and need to be processed with their own logic.</xd:desc>
    </xd:doc>
    <xsl:template match="*:dict|tei:standOff" mode="#all"/>
    
    <xd:doc>
        <xd:desc>The root element of BaseX'es JSON representation is json</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <json type="object">
            <xsl:apply-templates/>
        </json>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Group all elements with the same local-name together.
            Process multiple elements with a name as array.
            Use a very simple English 'plural' (+s) to destinguish such arrays from single elements.
            Some (TEI) elements are only used for looking up additional info, ignore them. 
        </xd:desc>
    </xd:doc>
    <xsl:template match="*">
        <xsl:apply-templates select="@*"/>
        <xsl:call-template name="group-xml-elements"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This handles the generation of JSON keys from XML elements.</xd:desc>
    </xd:doc>
    <xsl:template name="group-xml-elements">
        <xsl:for-each-group select="*|text()[normalize-space(.) ne '']" group-adjacent="local-name()">
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
            <xsl:when test="$element-group/local-name() = ''">
                <xsl:apply-templates select="$element-group" mode="#default"/> 
            </xsl:when>
            <xsl:when test="count($element-group) > 1">
                <xsl:variable name="content">
                    <xsl:apply-templates select="$element-group" mode="array"/>                       
                </xsl:variable>
                <xsl:if test="exists($content/(*|text()))">
                    <xsl:element name="{local-name()||'s'}">
                        <xsl:attribute name="type">array</xsl:attribute>
                        <xsl:sequence select="$content"/>
                    </xsl:element>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="content">
                    <xsl:apply-templates select="$element-group" mode="#default"/>                    
                </xsl:variable>
                <xsl:if test="exists($content/(*|text()))">
                    <xsl:element name="{local-name()}">
                        <xsl:attribute name="type">object</xsl:attribute>
                        <xsl:sequence select="$content"/>
                    </xsl:element>
                </xsl:if>
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
        <xsl:for-each-group select="*|text()[normalize-space(.) ne '']" group-adjacent="local-name()">
            <_ type="object">
                <xsl:call-template name="element-number-processing-switch">
                    <xsl:with-param name="element-group" select="current-group()"/>
                </xsl:call-template>
            </_>
        </xsl:for-each-group>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Multiple text nodes are transformed to a key '$$' and an array value.
        These text nodes can be mixed with elements.</xd:desc>
    </xd:doc>   
    <xsl:template match="*[normalize-space(string-join(text())) ne '' and count(text()) > 1]">        
        <xsl:apply-templates select="@*"/>
        <_0024_0024 type="array">
            <xsl:attribute name="type">array</xsl:attribute>
            <xsl:apply-templates select="." mode="sequence"/>
        </_0024_0024>        
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
    <xsl:template match="text()">
        <_0024><xsl:value-of select="normalize-space(.)"/></_0024>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>A text node that is part of multiple elements grouped together.</xd:desc>
    </xd:doc>
    <xsl:template match="text()" mode="array">
        <_><_0024><xsl:value-of select="normalize-space(.)"/></_0024></_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>TEI feature structures are key value representations.
            Transforming them directly to JSON objects seems to be the best way of dealing with them.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs" mode="#default">
        <xsl:element name="{@type}">
            <xsl:attribute name="type">object</xsl:attribute>
            <xsl:apply-templates mode="tei-fs"/>
        </xsl:element>
    </xsl:template>

    <xd:doc>
        <xd:desc>TEI feature structures are key value representations.
            This is the variant for multiple feature structures at the same XML level.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:fs" mode="array sequence">
        <_ type="object">
            <xsl:element name="{@type}">
                <xsl:attribute name="type">object</xsl:attribute>
                <xsl:apply-templates mode="tei-fs"/>
            </xsl:element>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Key and value in a feature are modeled using attributes and two elements.
            Transform them to simply "key": "value" pairs. 
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:f" mode="tei-fs">
        <xsl:element name="{@name}">
            <xsl:value-of select="tei:symbol/@value"/>
        </xsl:element>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Text nodes on feature structures generally do not convey any information.
            Ignore text nodes in TEI feature structures.
        </xd:desc>
    </xd:doc>
    <xsl:template match="text()" mode="tei-fs"/>
</xsl:stylesheet>
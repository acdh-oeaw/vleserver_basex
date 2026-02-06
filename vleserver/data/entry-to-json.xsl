<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:_="urn:_"
    exclude-result-prefixes="xs math xd tei _"
    version="3.0">
    
    <xd:doc>
        <xd:desc>This stylesheet specializes the generic TEI/XML to BaseX JSON XML to deal with some pecularities of our dictionaries.
            It is meant as an example how this could provide better results in JSON serialization.
            This stylesheet can also be used to transform an entry with no references or a whole dictionary.
        </xd:desc>
    </xd:doc>
    
    <xsl:import href="xml-to-basex-json-xml.xsl"/>
    <xsl:param name="referencedEntriesSerialize"/>
    <xsl:variable name="referencedEntries" select="(parse-xml-fragment($referencedEntriesSerialize)/*, multipleParts/param_referencedEntriesSerialized/*)"/>
    <_:output method="json"/>
    <xsl:output method="xml" indent="true" omit-xml-declaration="true"/>
    
    <xsl:key name="local-xml-ids" match="*[@xml:id]" use="@xml:id"/>
   
    <xsl:template match="tei:div" mode="named-object">
        <xsl:apply-templates select="* except (tei:entry, tei:cit)"/>
        <xsl:apply-templates select="(tei:entry, tei:cit)" mode="tei-cit-or-entry"/>
    </xsl:template>
    
    <xsl:template match="tei:entry|tei:cit" mode="tei-cit-or-entry">
        <xsl:element name="{local-name()}">
            <xsl:attribute name="type">object</xsl:attribute>          
            <xsl:apply-templates select="."/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="tei:ref" mode="#default array">
        <xsl:variable name="target" select="xs:string(@target)"/>
        <xsl:choose>
            <xsl:when test="$referencedEntries//*[@xml:id = substring($target, 2)]">
                <xsl:call-template name="element-number-processing-switch">
                    <xsl:with-param name="element-group" select="$referencedEntries//*[@xml:id = substring($target, 2)]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <ref type="object">
                    <xsl:apply-templates select="@*"/>
                    <_0024>target not found</_0024>
                </ref>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Construction gramGrp members work differently than the gramGrp used to describe lemmas</xd:desc>
    </xd:doc>
    <xsl:template match="tei:gram[@type='construction']" mode="#default">
       <construction__grams type="array">
           <_ type="array">
              <xsl:apply-templates select='.' mode="sequence"/>
            </_>
       </construction__grams>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Construction gramGrp members work differently than the gramGrp used to describe lemmas</xd:desc>
    </xd:doc>
    <xsl:template match="tei:gram[@type='construction'][position() = 1]" mode="array">
        <construction__grams type="array">
            <xsl:for-each select="(., ./following-sibling::*)">
               <_ type="array">                   
                   <xsl:apply-templates select='.' mode="sequence"/>  
               </_> 
            </xsl:for-each>
        </construction__grams>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Delete, already processed above</xd:desc>
    </xd:doc>
    <xsl:template match="tei:gram[@type='construction'][position() > 1]" mode="array"/>
    
    <xd:doc>
        <xd:desc>tei:ref are usually treated as pointers within the document. As @type oRef they point to something in a sentence structure</xd:desc>
    </xd:doc>
    <xsl:template match="tei:ref[@type='oRef']" mode="sequence">
        <_ type="object">
            <oRef__ref type="object">
              <xsl:apply-templates select="@*|*" mode="#default"/>
            </oRef__ref>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>Refs (except oRefs) should always point to some other part of the dictionary that can be resolved.
            We resolve the @target here and put the referenced parts into the ref, which should be empty.
            Sometimes this is not true. Sometimes the xml:ids are not unique or otherwise form infinite recursions.
        </xd:desc>
        <xd:param name="current-targets">Currently known targets for recursive calls</xd:param>
    </xd:doc>
    <xsl:template match="tei:ref[@target]">
        <xsl:param name="current-targets" tunnel="true" as="xs:string*"/>
        <xsl:variable name="target" select="substring(data(@target),2)"/>
        <xsl:variable name="content">
          <xsl:choose>
              <xsl:when test="$target = $current-targets">
                  <xsl:apply-templates select="@*|*|text()"/>
                  <loop><xsl:value-of select="$target"/></loop>
              </xsl:when>
              <xsl:otherwise>
                  <xsl:apply-templates select="($referencedEntries/descendant-or-self::*[@xml:id=$target], key('local-xml-ids', $target))[1]" mode="tei-cit-or-entry">
                      <xsl:with-param name="current-targets" tunnel="true" select="($target, $current-targets)"/>
                  </xsl:apply-templates>
              </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="exists($content)"><xsl:sequence select="$content"/></xsl:when>
            <xsl:otherwise><xsl:apply-templates select="@*|*|text()"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
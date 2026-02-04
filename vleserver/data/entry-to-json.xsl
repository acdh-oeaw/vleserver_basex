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
    
    <xsl:key name="local-xml-ids" match="*[@xml:id]" use="@xml:id"/>
    
    <xd:doc>
        <xd:desc>This non xsl output and xsl:output enable the RestAPI to select this stylesheet for processing to JSON.
            The actual transformation to JSON is part of BaseX.</xd:desc>
    </xd:doc>
    <_:output method="json"/>
    <xsl:output method="xml" indent="true" omit-xml-declaration="true"/>
    
    <xd:doc>
        <xd:desc>This is meant as a multi purpose entry point.
            There is a debug output of XML found in the database that returns a source and referenced XML snippets.
            This stylesheet can also be used to transform an entry with no references or a whole dictionary.
        </xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <json type="object">
            <xsl:apply-templates select="if (exists(multipleParts/xmlSource/*)) then multipleParts/xmlSource/* else (*|text())" mode="named-object"/>
        </json>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>If we process a dictionary file the entries and examples are encased in divs.
            The RestAPI also encases and entry in a div.
            So we deal with a div and one entry or cit or a div with multimple entries or cits here. 
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:div">
        <xsl:apply-templates select="* except (tei:entry, tei:cit)"/>
        <xsl:choose>
            <xsl:when test="count((tei:entry, tei:cit)) > 1">
                <xsl:if test="count(tei:entry) > 1">
                    <entries type="array">
                        <xsl:apply-templates select="tei:entry" mode="tei-cit-or-entries"/> 
                    </entries>
                </xsl:if>
                <xsl:if test="count(tei:cit) > 1">
                    <cits type="array">
                        <xsl:apply-templates select="tei:cit" mode="tei-cit-or-entries"/> 
                    </cits>
                </xsl:if>               
            </xsl:when>
            <xsl:otherwise><xsl:apply-templates select="(tei:entry, tei:cit)" mode="tei-cit-or-entry"/></xsl:otherwise>
        </xsl:choose>       
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The order of the elements in an entry has relevance so we use the seqence of objects method here.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:entry" mode="tei-cit-or-entry">
        <entry type="array">
            <xsl:apply-templates select="." mode="sequence"/>
        </entry>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The order of the elements in a cit has relevance so we use the seqence of objects method here.
        </xd:desc>
    </xd:doc>   
    <xsl:template match="tei:cit" mode="tei-cit-or-entry">
        <cit type="array">
            <xsl:apply-templates select="." mode="sequence"/>
        </cit>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The order of the elements in an entry has relevance so we use the seqence of objects method here.
            This is used when the entry is part of an array of entries.
        </xd:desc>
    </xd:doc>   
    <xsl:template match="tei:entry" mode="tei-cit-or-entries">
        <_ type="object">
            <entry type="array">
                <xsl:apply-templates select="." mode="sequence"/>
            </entry>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The order of the elements in a cit has relevance so we use the seqence of objects method here.
            This is used when the cit is part of an array of cits.
        </xd:desc>
    </xd:doc>    
    <xsl:template match="tei:cit" mode="tei-cit-or-entries">
        <_ type="object">
            <cit type="array">
                <xsl:apply-templates select="." mode="sequence"/>
            </cit>
        </_>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>In sense we have multiple cits with different types which have an order that matters.
            Additionally senses are generated in the entry context that also has an order that matters.
        </xd:desc>
    </xd:doc>
    <xsl:template match="tei:sense" mode="#default array">
        <_ type="object">
            <sense type="array">
                <xsl:apply-templates select='.' mode="sequence"/>
            </sense>
        </_>
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
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:letex		= "http://www.le-tex.de/namespace"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://www.le-tex.de/namespace/hub"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xpath-default-namespace = "http://docbook.org/ns/docbook"
    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn css xlink o w m wp r">

  <!-- ================================================================================ -->
  <!-- VARIABLES -->
  <!-- ================================================================================ -->
  
  <xsl:key name="by-genid" match="*" use="generate-id()"/>

  <xsl:variable name="page-settings" as="element(w:sectPr)">
    <xsl:variable name="a4-portrait-width" select="11906" as="xs:integer" />
    <xsl:variable name="a4-portrait-height" select="16838" as="xs:integer" />
    <xsl:variable name="sqrt2" select="1.41421356" as="xs:double" />
    <xsl:variable name="height" select="if ($a3paper eq 'yes') then xs:integer($sqrt2 * $a4-portrait-height) else $a4-portrait-height" as="xs:integer" />
    <xsl:variable name="width" select="if ($a3paper eq 'yes') then xs:integer($sqrt2 * $a4-portrait-width) else $a4-portrait-width" as="xs:integer" />
    <w:sectPr>
      <w:pgSz w:w="{if ($landscape eq 'yes') then $height else $width}" w:h="{if ($landscape eq 'yes') then $width else $height}"
        w:orient="{if ($landscape eq 'yes') then 'landscape' else 'portrait'}"/>
      <w:pgMar w:top="960" w:right="960" w:bottom="960" w:left="800" w:header="709" w:footer="709" w:gutter="0"/>
      <w:cols w:space="708"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </xsl:variable>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="*[@role eq 'web']"  mode="hub:default" priority="2000">
    <xsl:message>Ignoring role=web content: 
    <xsl:copy-of select="." />
    </xsl:message>
  </xsl:template>

  <xsl:template  match="*[@role eq 'print']"  mode="hub:default" priority="2000">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="info"  mode="hub:default"/>

  <!-- need this for subsequent key() operations (they are in disguise sometimes!) -->
  <xsl:variable name="root" select="/" as="document-node(element(*))" />

  <xsl:template  match="/*"  mode="hub:default">
    <!-- speed up the index-of() a little bit -->
    <xsl:variable  name="rels" select="for $f 
      in (  //*[local-name() = ('mediaobject', 'inlinemediaobject')] 
      (: | //link[@role eq 'uri' or (not(@role) and @xlink:href)] :)
      ) 
      return generate-id($f)" as="xs:string*"/>
    <w:root_converted>
      <w:containerProps>
        <xsl:apply-templates select="info/keywordset[@role = 'custom-meta']" mode="#current"/>
      </w:containerProps>
      <w:styles />
      <w:numbering>
        <xsl:apply-templates mode="numbering"/>
      </w:numbering>
      <w:footnotes>
        <xsl:apply-templates mode="footnotes"/>
      </w:footnotes>
      <w:endnotes />
      <w:settings >
        <xsl:apply-templates select="info/keywordset[@role = 'docVars']" mode="#current"/>
      </w:settings>
      <w:comments>
        <xsl:apply-templates mode="comments"/>
      </w:comments>
      <w:fonts />
      <w:docRels>
        <rel:Relationships>
          <xsl:apply-templates select="key('by-genid', $rels, $root)" mode="documentRels">
            <xsl:with-param name="rels" select="$rels" as="xs:string*" tunnel="yes"/>
          </xsl:apply-templates>
        </rel:Relationships>
      </w:docRels>
      <w:header>
        <xsl:for-each select="//*[not(parent::css:page)][@css:page][letex:is-header(.)]">
          <xsl:apply-templates select="." mode="header"/>
        </xsl:for-each>
      </w:header>
      <w:footer>
        <xsl:for-each select="//*[not(parent::css:page)][@css:page][letex:is-footer(.)]">
          <xsl:apply-templates select="." mode="footer"/>
        </xsl:for-each>
      </w:footer>
      <w:document>
        <w:body>
          <xsl:next-match>
            <xsl:with-param name="rels" select="$rels" as="xs:string*" tunnel="yes"/>
          </xsl:next-match>
        </w:body>
      </w:document>
    </w:root_converted>
  </xsl:template>
  
  <xsl:template  match="book | Body | hub"  mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="keywordset[@role = 'custom-meta']" mode="hub:default">
    <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"> 
      <xsl:apply-templates mode="#current"/>
    </Properties>
  </xsl:template>

  <xsl:template match="keywordset[@role = 'custom-meta']/keyword" mode="hub:default">
    <property xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"
      fmtid="{{D5CDD505-2E9C-101B-9397-08002B2CF9AE}}" pid="fill-me-with-an-int" name="{@role}"> 
      <vt:lpwstr>
        <xsl:value-of select="."/>
      </vt:lpwstr>
    </property>
  </xsl:template>
  
  <xsl:template match="keywordset[@role = 'docVars']" mode="hub:default">
    <w:docVars>
      <xsl:apply-templates mode="#current"/>
    </w:docVars>
  </xsl:template>

  <xsl:template match="keywordset[@role = 'docVars']/keyword" mode="hub:default">
    <w:docVar w:name="{@role}" w:val="{.}"/>
  </xsl:template>
  
  <xsl:template  match="chapter"  mode="hub:default" priority="123">
    <xsl:message select="'...Chapter: ', string-join(title//text()[not(ancestor::indexterm)], '')"/>
    <xsl:apply-templates  select="node()"  mode="#current" />
  </xsl:template>
  

  <xsl:template  match="section | sect1 | sect2 | sect3 | sect4 | sect5 | sect6 | appendix | preface | blockquote"  mode="hub:default">
    <xsl:apply-templates  select="node()"  mode="#current" />
  </xsl:template>
  
  <xsl:template  match="titleabbrev"  mode="hub:default" />

  <xsl:function name="letex:headinglevel" as="xs:integer">
    <xsl:param name="context" as="element(*)?" />
    <xsl:variable  name="origLevel" select="replace( $context/../@role, '(^| )head([0-9]*).*$', '$2')" as="xs:string?"/>
    <xsl:value-of select="if ( $origLevel castable as xs:integer) then number($origLevel) + 1 
                          else count( $context/(ancestor::part | ancestor::chapter | ancestor::*[starts-with(local-name(), 'sect')]) ) + 1"/>
  </xsl:function>

  <xsl:template  match="title[   parent::chapter | parent::section | parent::glossary 
                               | parent::preface | parent::appendix | parent::bibliography
                               | parent::sect1 | parent::sect2 | parent::sect3 | parent::sect4 | parent::sect5 | parent::sect6 
                             ]"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{concat( $heading-prefix, string(letex:headinglevel(.)))}"/>
      </w:pPr>
      <xsl:variable name="rPrContent" as="element(w:color)?">
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes" as="element(*)*"/>
      </xsl:apply-templates>
      <xsl:if test="../@xml:id">
        <w:bookmarkEnd    w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
  </xsl:template>

  <xsl:template match="w:bookmarkStart/@w:id | w:bookmarkEnd/@w:id" mode="hub:clean">
    <xsl:param name="bookmark-ids" as="xs:string+" tunnel="yes"/>
    <xsl:attribute name="{name()}" select="index-of($bookmark-ids, .)"/>
  </xsl:template>

  <xsl:template  match="book/title | book/subtitle"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{concat(
                           upper-case(
                             substring(name(.),1,1)
                           ),
                           substring(name(.),2)
                         )}"/>
      </w:pPr>
      <xsl:apply-templates mode="#current" />
    </w:p>
  </xsl:template>

  <xsl:template  match="title[ parent::blockquote ]"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="blockquotetitle"/>
      </w:pPr>
      <xsl:variable name="rPrContent" as="element(*)*">
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes" as="element(*)*"/>
      </xsl:apply-templates>
      <xsl:if test="../@xml:id">
        <w:bookmarkEnd    w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
  </xsl:template>
  

  <xsl:template  match="title"  mode="hub:default"  priority="-1">
    <xsl:message  terminate="yes" select="concat( 'ERROR: title parent not expected: ', parent::*/name())"/>
  </xsl:template>


</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>

<!--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~     Authors: Gerrit Imsieke, Ralph Krüger                                                                             ~
~              (C) le-tex publishing services GmbH Leipzig (2010)                                                       ~
~                                                                                                                       ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:letex		= "http://www.le-tex.de/namespace"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://www.le-tex.de/namespace/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn xlink o w m wp r"
>

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
    <w:root_converted>
      <w:styles />
      <w:numbering>
        <xsl:apply-templates mode="numbering"/>
      </w:numbering>
      <w:footnotes>
        <xsl:apply-templates mode="footnotes"/>
      </w:footnotes>
      <w:endnotes />
      <w:settings />
      <w:fonts />
      <w:docRels />
      <w:document>
        <w:body>
          <xsl:next-match/>
        </w:body>
      </w:document>
    </w:root_converted>
  </xsl:template>

  <xsl:template  match="book | Body"  mode="hub:default">
    <xsl:apply-templates mode="#current" />
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
      <xsl:variable name="rPrContent">
				<xsl:variable name="color" select="replace( letex:current-color(., (), ()), '#', '' )" />
        <xsl:if test="$color">
          <w:color w:val="{$color}"/>
        </xsl:if>
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes"/>
      </xsl:apply-templates>
      <xsl:if test="../@xml:id">
        <w:bookmarkEnd    w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
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
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes"/>
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

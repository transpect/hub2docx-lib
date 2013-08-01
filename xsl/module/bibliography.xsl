<?xml version="1.0" encoding="UTF-8"?>

<!--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~     Authors: Gerrit Imsieke, Ralph Krüger                                                                             ~
~              (C) le-tex publishing services GmbH Leipzig (2010)                                                       ~
~                                                                                                                       ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<!DOCTYPE xsl:stylesheet
  [
    <!ENTITY xpathListElement			"*[ local-name() = ( 'itemizedlist' , 'orderedlist', 'bibliography', 'bibliodiv' )]" >
  ]
>

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

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink o w m wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="bibliography"  mode="hub:default" >
    <xsl:apply-templates  select="node()"  mode="#current" />
  </xsl:template>


  <xsl:template  match="bibliography/title"  mode="hub:default" >
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Heading{letex:headinglevel(ancestor::*[self::section or self::chapter][1]/title) + 1}"/>
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="#current" />
    </w:p>
  </xsl:template>


  <xsl:template  match="bibliodiv"  mode="hub:default" >
    <xsl:apply-templates  mode="#current" />
  </xsl:template>


  <xsl:template  match="bibliodiv/title"  mode="hub:default" >
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Heading{letex:headinglevel(ancestor::*[self::section or self::chapter][1]/title) + 2}"/>
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="#current" />
    </w:p>
  </xsl:template>


  <xsl:template  match="bibliolist"     mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="biblioentry" mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="bibliomixed"    mode="hub:default">
    <xsl:variable  name="footnoteId"  select="generate-id()"/>
    <w:bookmarkStart w:id="{$footnoteId}" w:name="bm_{$footnoteId}_"/>
    <xsl:apply-templates  select="node()"  mode="#current" />
    <w:bookmarkEnd w:id="{$footnoteId}"/>
  </xsl:template>


  <xsl:template  match="bibliomisc"    mode="hub:default">
    <w:p>
      <w:pPr>
        <xsl:choose>
          <xsl:when  test="@role eq 'numberedRef'">
            <w:pStyle w:val="bibnum"/>
            <w:numPr>
              <w:ilvl w:val="0"/>
              <w:numId w:val="{letex:getNumId( ancestor::*[self::&xpathListElement;][1]/generate-id() )}" />
            </w:numPr>
          </xsl:when>
          <xsl:otherwise>
            <w:pStyle w:val="bib"/>
          </xsl:otherwise>
        </xsl:choose>
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="#current" />
    </w:p>
  </xsl:template>


</xsl:stylesheet>

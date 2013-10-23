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

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn css xlink o w m wp r"
>

  <!--
       Input example (display header on right and left pages, but not on first page):
       <hub>
         <info>
           <css:page pseudo="left right" name="myheader">
             <css:page-margin-box location="top-center"/>
           </css:page>
         </info>
         <sidebar css:page="myheader"><para>My Header</para></sidebar>
  -->

  <xsl:variable name="originalHeaderIds" as="xs:string*"
    select="for $h in //*[letex:resolve-header(.)] return generate-id($h)" />

  <xsl:function name="letex:header-id" as="xs:integer">
    <xsl:param name="header" as="element(sidebar)" />
    <xsl:sequence select="index-of($originalHeaderIds, generate-id($header))" />
  </xsl:function>

  <xsl:template match="*[letex:resolve-header(.)]" mode="header">
    <w:hdr hub:offset="{letex:header-id(.)}">
      <xsl:for-each select="tokenize(letex:resolve-header(.)/@pseudo, '&#x20;')">
        <xsl:choose>
          <xsl:when test=". eq 'first'">
            <xsl:attribute name="hub:header-first" select="'true'"/>
          </xsl:when>
          <xsl:when test=". eq 'right'">
            <xsl:attribute name="hub:header-default" select="'true'"/>
          </xsl:when>
          <xsl:when test=". eq 'left'">
            <xsl:attribute name="hub:header-even" select="'true'"/>
          </xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
      </xsl:for-each>
      <xsl:apply-templates mode="hub:default"/>
    </w:hdr>
  </xsl:template>

</xsl:stylesheet>

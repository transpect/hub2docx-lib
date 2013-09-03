<?xml version="1.0" encoding="UTF-8"?>

<!--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~     Authors: Gerrit Imsieke, Ralph Krüger                                                                             ~
~              (C) le-tex publishing services GmbH Leipzig (2010)                                                       ~
~                                                                                                                       ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<!DOCTYPE xsl:stylesheet>

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

  <!-- See also lists.xsl (preprocesses paras that contain lists)
       -->

  <xsl:template  match="para[ not( parent::listitem) ]"  mode="hub:default">
    <xsl:variable name="pPr">
      <xsl:apply-templates  select="@role, .//phrase[@role eq 'pageBreakBefore']"  mode="props" />
    </xsl:variable>
    <w:p>
      <xsl:if  test="$pPr">
        <w:pPr>
          <xsl:sequence  select="$pPr" />
        </w:pPr>
      </xsl:if>
      <xsl:if test="@xml:id">
        <w:bookmarkStart w:id="{generate-id()}"  w:name="bm_{generate-id(.)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current"/>
      <xsl:if test="@xml:id">
        <w:bookmarkEnd w:id="{generate-id()}"/>
      </xsl:if>
    </w:p>
  </xsl:template>

  <xsl:template  match="para[ parent::blockquote ]"  mode="hub:default" priority="2">
    <xsl:variable name="pPr">
      <xsl:apply-templates  select="@role, .//phrase[@role eq 'pageBreakBefore']"  mode="props" />
      <w:pStyle w:val="BlockText"/>
    </xsl:variable>
    <w:p>
      <xsl:if  test="$pPr">
        <w:pPr>
          <xsl:sequence  select="$pPr" />
        </w:pPr>
      </xsl:if>
      <xsl:if test="@xml:id">
        <w:bookmarkStart w:id="{generate-id()}"  w:name="bm_{generate-id(.)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current"/>
      <xsl:if test="@xml:id">
        <w:bookmarkEnd w:id="{generate-id()}"/>
      </xsl:if>
    </w:p>
  </xsl:template>

  <xsl:template match="simpara[not(parent::footnote)]" mode="hub:default">
    <w:p>
      <xsl:apply-templates mode="#current" />
    </w:p>
  </xsl:template>

  <xsl:template match="@role" mode="props">
    <xsl:if test="matches(., 'item')">
      <w:ind w:left="360" />
    </xsl:if>
    <w:pStyle hub:val="{.}" />
<!--
    <xsl:if test="matches(., 'unreferencedFootnote')">
      <w:pStyle w:val="UnreferencedFootnote" />
    </xsl:if>
-->
  </xsl:template>

  <xsl:template match="phrase[@role eq 'pageBreakBefore']" mode="props">
    <w:pageBreakBefore/>
  </xsl:template>

</xsl:stylesheet>

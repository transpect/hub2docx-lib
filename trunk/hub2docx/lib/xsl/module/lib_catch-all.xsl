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
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:docx2hub      = "http://www.le-tex.de/namespace/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn dbk xlink o w m wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- copied from letex-base/funct-letex-match-all.xsl: -->
  <!-- catch anything else rule for all modes - with proper xslt-coding, this should never be activated and, therefore, throws a warning message -->
  <xsl:template match="*"
                mode="hub:default"
                priority="-1000">
    <xsl:copy>
      <xsl:copy-of          select="@*"/>
      <xsl:attribute        name="hub:default-no-match"  select="'true'"/>
      <xsl:apply-templates  select="node()"  mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="processing-instruction()" mode="hub:default" priority="-1" />

  <xsl:template match="comment()" mode="hub:default" priority="-1" />

  <xsl:template match="node() | @*"
    mode="hub:default hub:default_renderFootnote hub:clean footnotes header footer comments glossary2table patchTemplateFile extract-text numbering props trPr tcPr remove-misplaced-runs"
                priority="-1001">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()" mode="documentRels" priority="-1001">
    <xsl:apply-templates  mode="#current" />
  </xsl:template>
  
  <xsl:template match="@*" mode="documentRels" priority="-1001">
    <xsl:attribute name="{name(.)}" select="."/>>
  </xsl:template>

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default_documentRels" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- by default, in this mode all nodes will just be traversed -->

  <xsl:template  match="node()"  mode="hub:default_documentRels"  priority="-100">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="clean" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- remove text runs that stem from ignorable whitespace in the source -->

  <xsl:template  match="@docx2hub:origin"  mode="hub:clean" priority="100"/>

  <xsl:template  match="w:r[not(parent::w:p or parent::w:hyperlink)]"  mode="hub:clean" />
<!-- <xsl:template  match="w:body/w:r"  mode="clean" /> -->

  <!-- dissolve w:p that include other w:p or w:tbl (because there were tables in paras, for example)
    Preprocessing these paras might be a better alternative, but … -->
  <xsl:template match="w:p[w:p | w:tbl][every $c in * satisfies ($c/local-name() = ('pPr', 'p', 'tbl')) (: no text runs :)]" 
    mode="hub:clean">
    <xsl:apply-templates select="* except w:pPr" mode="#current"/>
  </xsl:template>

  <xsl:template  match="/*"  mode="hub:clean">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:variable name="no-match-elements" as="element(*)*"
        select=".//*[@hub:default-no-match eq 'true']"/>
      <xsl:for-each select="distinct-values(for $i in $no-match-elements return name($i))">
        <xsl:message  select="concat(
                                '&#x0A;&#x09;&#x09;WARNING: The element &quot;', current(),
                                '&quot; (Occurrence: ', count($no-match-elements[name() eq current()]),
                                ') will just be copied by a &quot;match anything&quot; template for mode=&quot;#all&quot;',
                                '&#x0A;&#x09;&#x09;This should not happen. Please contact the hub2docx maintainer.')"/>
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>
  <xsl:template  match="@hub:default-no-match | @hub:morerows"  mode="hub:clean" />

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:docx2hub      = "http://transpect.io/docx2hub"
    xmlns:tr		= "http://transpect.io"

  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"
  xmlns:w16cid="http://schemas.microsoft.com/office/word/2016/wordml/cid"
  xmlns:w16se="http://schemas.microsoft.com/office/word/2015/wordml/symex" xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:ct="http://schemas.openxmlformats.org/package/2006/content-types" 
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon saxExtFn dbk xlink o w m r docx2hub tr"
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
      <xsl:sequence          select="@*"/>
      <xsl:attribute        name="hub:default-no-match"  select="'true'"/>
      <xsl:apply-templates  select="node()"  mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="processing-instruction()" mode="hub:default" priority="-1" />

  <xsl:template match="comment()" mode="hub:default" priority="-1" />

  <xsl:template match="node() | @*"
    mode="hub:group hub:default hub:clean footnotes header footer comments glossary2table patchTemplateFile extract-text numbering props trPr tcPr remove-misplaced-runs"
                priority="-1001">
    <!-- Must. Not. Add. copy-namespaces="no" 
         Otherwise it’ll break at some point (for ex. when you include wp14: elements, or graphics) -->
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()" mode="documentRels" priority="-1001">
    <xsl:apply-templates  mode="#current" />
  </xsl:template>
  
  <xsl:template match="@*" mode="documentRels" priority="-1001">
    <xsl:attribute name="{name(.)}" select="."/>
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

  <xsl:template  match="@origin"  mode="hub:clean" priority="100"/>

  <xsl:template  match="w:r[not(parent::*[self::w:p or self::w:hyperlink or self::w:tc])]"  mode="hub:clean">
    <xsl:if test="some $t in w:t satisfies $t[text() and not(matches(., '^[\t\s\n&#xa;]+$'))]">
      <w:p>
        <xsl:copy-of select="."/>
      </w:p>
      <xsl:message select="'hub2docx warning: invalid run-text with content from word-document: ', w:t//text()[not(matches(., '^[\t\s\n&#xa;]+$'))]"/>
    </xsl:if>
  </xsl:template>
<!-- <xsl:template  match="w:body/w:r"  mode="clean" /> -->

  <!-- dissolve w:p that include other w:p or w:tbl (because there were tables in paras, for example)
    Preprocessing these paras might be a better alternative, but … -->
  <xsl:template match="w:p[w:p | w:tbl][every $c in * satisfies ($c/local-name() = ('pPr', 'p', 'tbl')) (: no text runs :)]" 
    mode="hub:clean">
    <xsl:apply-templates select="* except w:pPr" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="w:p[not(every $c in * satisfies ($c/local-name() = ('pPr', 'p', 'tbl')))]/w:p" mode="hub:clean" priority="-1">
    <xsl:apply-templates select="node() except w:pPr" mode="#current"/>
  </xsl:template>

  <xsl:template  match="/*"  mode="hub:clean">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current">
        <xsl:with-param name="bookmark-ids" select="descendant::w:bookmarkStart/@w:id" tunnel="yes"/>
      </xsl:apply-templates>
      <xsl:variable name="no-match-elements" as="element(*)*"
        select=".//*[@hub:default-no-match eq 'true'][not(name() = ('css:rule', 'css:rules', 'keyword', 'keywordset'))]"/>
      <xsl:for-each select="distinct-values(for $i in $no-match-elements return name($i))">
        <xsl:message  select="concat(
                                '&#x0A;&#x09;&#x09;WARNING: The element &quot;', current(),
                                '&quot; (Occurrence: ', count($no-match-elements[name() eq current()]),
                                ') is unknown and will be removed from the final document!',
                                '&#x0A;&#x09;&#x09;This should not happen (in mode hub:clean)! Please contact the hub2docx maintainer.')"/>
      </xsl:for-each>
      <xsl:if test=".//w:rStyle/@hub:inline-role-in-template">
        <xsl:message select="'&#xa;Following inline roles are mapped with corresponding format in template:', 
                              distinct-values(.//w:rStyle[@hub:inline-role-in-template eq 'yes']/@w:val)"/>
      </xsl:if>
      <xsl:if test=".//w:pStyle/@hub:para-role-in-template">
        <xsl:message select="'&#xa;Following para roles are mapped with corresponding format in template:', 
                              distinct-values(.//w:pStyle[@hub:para-role-in-template eq 'yes']/@w:val)"/>
      </xsl:if>
      <xsl:if test="$create-and-map-styles-not-in-template = 'yes'">
        <xsl:message select="'&#xa;Total number of newly created styles from css:rules of input:', 
                              count(.//w:style[@hub:is-css-style eq 'yes'])"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
  <xsl:template  match="*[@hub:default-no-match] | @hub:morerows"  mode="hub:clean" />
  <xsl:template  match="@hub:inline-role-in-template | @hub:para-role-in-template"  mode="hub:clean" />
  <xsl:template  match="@hub:is-css-style"  mode="hub:clean" />

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:letex		= "http://www.le-tex.de/namespace"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://www.le-tex.de/namespace/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
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

  <!-- ~~~~~~~~~~~~~~~~~~~~ rendering of the markers ~~~~~~~~~~~~~~~~~~~~ -->

  <!-- Please note, that using the footnote concept of Office Open XML does not suit our needs in case of the Hogrefe CHPD-data, because we need to control the placement of the footnotetexts.
       Within the text flow, a footnote generates the marker, which is linked to the textfield the footnotetext starts with (the marker).
       The footnote-marker heading the footnotetext has to be coded as textfield in order to be able to reference the footnotetext. See, e.g., mode="hub:default_renderFootnote".
       -->
  <!-- DISABLED -->
  <xsl:template  match="footnote[ancestor::tr or ancestor::row]"  mode="hub:default_">
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve"> HYPERLINK \l bm_<xsl:value-of  select="generate-id()"/>_  \o "Table footnote <xsl:value-of  select="@label"/>"</w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="separate"/>
    </w:r>
    <w:r>
      <w:rPr>
        <!-- §§ should be a proper rStyle -->
        <w:vertAlign w:val="superscript"/>
      </w:rPr>
      <w:t><xsl:value-of  select="@label"/></w:t>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>

  <xsl:variable name="originalFootnoteIds" as="xs:string*"
    select="for $f in //footnote return generate-id($f)" />
  
  <xsl:template  match="footnote"  mode="hub:default">
    <!-- 200000 arbitrary number to make the bookmark id hopefully unique. Need a better mechanism -->
    <xsl:variable  name="footnoteId"  select="letex:fn-id(.)"/>
    <w:bookmarkStart w:id="{letex:fn-bm-id(.)}" w:name="{letex:fn-bookmark(.)}"/>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{(collection()//w:styles/w:style[w:name/@w:val = 'footnote reference']/@w:styleId, 'FootnoteReference')[1]}"/>
        <xsl:if test="matches(@label, '[&#xF000;-&#xF7FF;]')">
          <w:rFonts w:ascii="Wingdings" w:hAnsi="Wingdings" w:hint="default"/>
        </xsl:if>
      </w:rPr>
      <!-- The possible values for this attribute (w:id) are defined by the ST_DecimalNumber simple type
           (§17.18.10). -->
      <w:footnoteReference w:id="{letex:fn-id(.)}">
        <xsl:if test="@label">
          <xsl:attribute name="w:customMarkFollows" select="'1'" />
        </xsl:if>
      </w:footnoteReference>
      <xsl:if test="@label">
        <w:t>
          <xsl:value-of select="@label"/>
        </w:t>
      </xsl:if>
    </w:r>
    <w:bookmarkEnd w:id="{letex:fn-bm-id(.)}"/>
  </xsl:template>

  <xsl:function name="letex:fn-id" as="xs:integer">
    <xsl:param name="fn" as="element(footnote)" />
    <xsl:sequence select="index-of($originalFootnoteIds, generate-id($fn))" />
  </xsl:function>

  <xsl:function name="letex:fn-bm-id" as="xs:integer">
    <xsl:param name="fn" as="element(footnote)" />
    <xsl:sequence select="letex:fn-id($fn)" />
  </xsl:function>

  <xsl:function name="letex:fn-bookmark" as="xs:string">
    <xsl:param name="fn" as="element(footnote)" />
    <xsl:sequence select="concat('FN_', letex:fn-id($fn))" />
  </xsl:function>

  <!-- within the text flow, a footnoteref behaves exactly like the the referenced footnote -->
  <!-- DISABLED -->
  <xsl:template  match="footnoteref[ancestor::table or ancestor::informaltable]"    mode="hub:default_">
    <xsl:apply-templates  select="//footnote[ @xml:id eq current()/@linkend ]"  mode="#current"/>
  </xsl:template>

<!--  <xsl:template  match="footnoteref[not(ancestor::table or ancestor::informaltable)]" mode="hub:default">-->
  <xsl:template  match="footnoteref" mode="hub:default">
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve"> NOTEREF <xsl:value-of select="letex:fn-bookmark($root//footnote[ @xml:id eq current()/@linkend ])"/> \f \h</w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="separate"/>
    </w:r>
    <w:r>
      <w:t>?</w:t>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~ rendering of tablenotes ~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="para"  mode="hub:default_renderFootnote">
    <xsl:param name="fn" as="element(footnote)" tunnel="yes"/>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="TableFootnote" />
      </w:pPr>
      <xsl:choose>
        <xsl:when test=". is ../*[1] or (position() eq 1)"><!-- check also for pos=1 b/c it may be part of a sequence of paras, not of a document -->
          <w:bookmarkStart w:id="{letex:fn-bm-id($fn)}" w:name="{letex:fn-bookmark($fn)}"/>
          <w:r>
            <w:rPr>
              <!-- §§ should be a proper rStyle -->
              <w:vertAlign w:val="superscript"/>
            </w:rPr>
            <w:t><xsl:value-of  select="$fn/@label"/></w:t>
          </w:r>
          <w:bookmarkEnd w:id="{letex:fn-bm-id($fn)}"/>
        </xsl:when>
        <xsl:otherwise>
          <w:r>
            <w:tab/>
          </w:r>
        </xsl:otherwise>
      </xsl:choose>
      <!-- render the footnotetext -->
      <xsl:apply-templates mode="hub:default"/>
    </w:p>
  </xsl:template>

  <xsl:template  match="footnote[ancestor::tr or ancestor::row]"  mode="hub:default_renderFootnote">
    <xsl:apply-templates mode="#current">
      <xsl:with-param name="fn" select="." tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="footnotes" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="footnote"  mode="footnotes">
    <w:footnote w:id="{letex:fn-id(.)}">
      <xsl:apply-templates select="*[self::para or self::simpara][1]" mode="#current" />
      <xsl:apply-templates select="*[self::para or self::simpara][position() gt 1]" mode="hub:default">
        <xsl:with-param name="pPrContent">
          <w:pStyle w:val="{(collection()//w:styles/w:style[w:name/@w:val = 'footnote text']/@w:styleId, 'FootnoteText')[1]}"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </w:footnote>
  </xsl:template>

  <xsl:template match="footnote/para | footnote/simpara" mode="footnotes">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{(collection()//w:styles/w:style[w:name/@w:val = 'footnote text']/@w:styleId, 'FootnoteText')[1]}"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rStyle w:val="{(collection()//w:styles/w:style[w:name/@w:val = 'footnote reference']/@w:styleId, 'FootnoteReference')[1]}"/>
        </w:rPr>
        <xsl:choose>
          <xsl:when test="../@label">
            <w:t>
              <xsl:value-of select="../@label"/>
            </w:t>
          </xsl:when>
          <xsl:otherwise>
            <w:footnoteRef/>
          </xsl:otherwise>
        </xsl:choose>
      </w:r>
      <w:r>
        <w:t xml:space="preserve"> </w:t>
      </w:r>
      <xsl:apply-templates select="node() except *[self::itemizedlist or self::orderedlist]" mode="hub:default" />
    </w:p>
    <xsl:apply-templates select="itemizedlist union orderedlist" mode="hub:default" />
  </xsl:template>

  <xsl:template  match="node()"  mode="footnotes"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>


</xsl:stylesheet>

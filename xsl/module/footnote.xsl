<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink o w m wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:variable name="originalFootnoteIds" as="xs:string*"
    select="for $f in $root//footnote return $f/@xml:id" />
  
  <xsl:template  match="footnote"  mode="hub:default">
    <xsl:variable  name="footnoteId"  select="tr:fn-id(.)" as="xs:integer"/>
    <w:bookmarkStart w:id="{tr:fn-bm-id(.)}" w:name="{tr:fn-bookmark(.)}"/>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="{(collection($collection-uri)//w:styles/w:style[w:name/@w:val = 'footnote reference']/@w:styleId, 'FootnoteReference')[1]}"/>
        <xsl:if test="matches(@label, '[&#xF000;-&#xF7FF;]')">
          <w:rFonts w:ascii="Wingdings" w:hAnsi="Wingdings" w:hint="default"/>
        </xsl:if>
      </w:rPr>
      <!-- The possible values for this attribute (w:id) are defined by the ST_DecimalNumber simple type
           (§17.18.10). -->
      <w:footnoteReference w:id="{tr:fn-id(.)}">
        <xsl:if test="@label or para/phrase[@role='hub:identifier']/@xreflabel">
          <xsl:attribute name="w:customMarkFollows" select="'1'" />
        </xsl:if>
      </w:footnoteReference>
      <xsl:if test="@label or para/phrase[@role='hub:identifier']/@xreflabel">
        <w:t>
          <xsl:value-of select="(@label, para/phrase[@role='hub:identifier']/@xreflabel)[1]"/>
        </w:t>
      </xsl:if>
    </w:r>
    <w:bookmarkEnd w:id="{tr:fn-bm-id(.)}"/>
  </xsl:template>

  <xsl:function name="tr:fn-id" as="xs:integer">
    <xsl:param name="fn" as="element(footnote)" />
    <!-- use footnote/@xml:id instead of generate-id (footnotes in tables are temporary written in a variable 
         and so the generate-id returns another values than those in $originalFootnoteIds) -->
    <xsl:choose>
      <!-- all footnotes with xml:id attribute -->
      <xsl:when test="every $i in $root//footnote satisfies $i/@xml:id/normalize-space(.)">
        <xsl:sequence select="index-of($originalFootnoteIds, $fn/@xml:id)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="index-of($root//footnote/generate-id(), $fn/generate-id())"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:fn-bm-id" as="xs:integer">
    <xsl:param name="fn" as="element(footnote)" />
    <xsl:sequence select="tr:fn-id($fn)" />
  </xsl:function>

  <xsl:function name="tr:fn-bookmark" as="xs:string">
    <xsl:param name="fn" as="element(footnote)" />
    <xsl:sequence select="concat($footnote-bookmark-prefix, tr:fn-id($fn))" />
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
      <w:instrText xml:space="preserve"> NOTEREF <xsl:value-of select="tr:fn-bookmark($root//footnote[ @xml:id eq current()/@linkend ])"/> \f \h</w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="separate"/>
    </w:r>
    <w:r>
      <w:t>
        <xsl:value-of select="(@label, '?')[1]"/>
      </w:t>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>
  

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="footnotes" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="footnote"  mode="footnotes">
    <w:footnote w:id="{tr:fn-id(.)}">
      <xsl:apply-templates select="*[self::para or self::simpara][1]" mode="#current" />
      <xsl:apply-templates select="*[self::para or self::simpara][position() gt 1]" mode="hub:default">
        <xsl:with-param name="pPrContent">
          <w:pStyle w:val="{(collection($collection-uri)//w:styles/w:style[w:name/@w:val = 'footnote text']/@w:styleId, 'FootnoteText')[1]}"/>
        </xsl:with-param>
      </xsl:apply-templates>
    </w:footnote>
  </xsl:template>
  
  <xsl:template match="@srcpath" mode="footnotes"/>

  <xsl:template match="footnote/para | footnote/simpara" mode="footnotes">
    <w:p>
      <xsl:apply-templates select="anchor[@role=('w14:paraId','w14:textId')]" mode="hub:default"/>
      <w:pPr>
        <w:pStyle w:val="{(collection($collection-uri)//w:styles/w:style[w:name/@w:val = 'footnote text']/@w:styleId, 'FootnoteText')[1]}"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rStyle w:val="{(collection($collection-uri)//w:styles/w:style[w:name/@w:val = 'footnote reference']/@w:styleId, 'FootnoteReference')[1]}"/>
        </w:rPr>
        <xsl:choose>
          <xsl:when test="../@label or phrase[@role='hub:identifier']/@xreflabel">
            <w:t>
              <xsl:value-of select="(../@label, phrase[@role='hub:identifier']/@xreflabel)[1]"/>
            </w:t>
          </xsl:when>
          <xsl:otherwise>
            <w:footnoteRef/>
          </xsl:otherwise>
        </xsl:choose>
      </w:r>
      <xsl:if test="not(matches(string-join(text(),''),'^\p{Zs}'))">
        <w:r>
          <w:t xml:space="preserve"> </w:t>
        </w:r>
      </xsl:if>
      <xsl:apply-templates select="node() except *[self::itemizedlist or self::orderedlist or self::anchor[@role=('w14:paraId','w14:textId')]]" mode="hub:default" />
    </w:p>
    <xsl:apply-templates select="itemizedlist union orderedlist" mode="hub:default" />
  </xsl:template>

  <xsl:template  match="node()"  mode="footnotes"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>


</xsl:stylesheet>

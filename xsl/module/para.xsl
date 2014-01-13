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
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:docx2hub      = "http://www.le-tex.de/namespace/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink css o w m wp r docx2hub"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- See also lists.xsl (preprocesses paras that contain lists)
       -->

  <xsl:template  match="para[ not( parent::listitem) ]"  mode="hub:default">
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:perform-sort>
        <xsl:sort data-type="number" order="ascending">
          <xsl:apply-templates select="." mode="letex:propsortkey"/>
        </xsl:sort>
        <xsl:apply-templates  select="@css:page-break-after, @css:page-break-inside, @role, @css:page-break-before, @css:text-indent, (@css:widows, @css:orphans)[1], @css:margin-bottom, @css:margin-top, @css:line-height, @css:text-align" mode="props" />      
      </xsl:perform-sort>
    </xsl:variable>
    <w:p docx2hub:origin="default_p_parentnotlistitem">
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
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:apply-templates  select="@css:page-break-after, @css:page-break-inside, @role, @css:page-break-before, @css:text-indent, (@css:widows, @css:orphans)[1], @css:margin-bottom, @css:margin-top, @css:line-height, @css:text-align"  mode="props" />
      <w:pStyle w:val="BlockText"/>
    </xsl:variable>
    <w:p docx2hub:origin="default_p_parentblockq">
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
    <w:p docx2hub:origin="default_simpara">
      <xsl:apply-templates mode="#current" />
    </w:p>
  </xsl:template>

  <xsl:template match="@role[. = 'ttt:token']" mode="props"/>
    
  <xsl:template match="@role" mode="props">
    <xsl:variable name="rule" select="key('style-by-name', .)" as="element(css:rule)?"/>
    <xsl:choose>
      <xsl:when test="exists($rule)">
        <xsl:variable name="elt-name" as="xs:string">
          <xsl:choose>
            <xsl:when test="$rule/@layout-type = 'inline'">
              <xsl:sequence select="'w:rStyle'"/>
            </xsl:when>
            <xsl:when test="$rule/@layout-type = 'para'">
              <xsl:sequence select="'w:pStyle'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="parent::para">
                  <xsl:sequence select="'w:pStyle'"/>
                </xsl:when>
                <xsl:when test="parent::phrase">
                  <xsl:sequence select="'w:rStyle'"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message><xsl:value-of select="parent::*"/> not implemented as parent for @role="<xsl:value-of select="."/>"</xsl:message>
                  <xsl:sequence select="'implementMe'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$elt-name}">
          <xsl:attribute name="w:val" select="."/>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'para.xsl, match=@role: no style for role ', string(.)"/>
        <xsl:variable name="elt-name">
          <xsl:choose>
            <xsl:when test="parent::para">
              <xsl:sequence select="'w:pStyle'"/>
            </xsl:when>
            <xsl:when test="parent::phrase">
              <xsl:sequence select="'w:rStyle'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message><xsl:value-of select="parent::*"/> not implemented as parent for @role="<xsl:value-of select="."/>"</xsl:message>
              <xsl:sequence select="'implementMe'"/>
            </xsl:otherwise>
          </xsl:choose>  
        </xsl:variable>
        <xsl:element name="{$elt-name}">
          <xsl:attribute name="w:val" select="."/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@css:margin-bottom" mode="props">
    <w:spacing w:after="{letex:length-to-unitless-twip(.)}"/>
  </xsl:template>
  
  <xsl:template match="@css:margin-top" mode="props">
    <w:spacing w:before="{letex:length-to-unitless-twip(.)}"/>
  </xsl:template>
  
  <xsl:template match="@css:line-height" mode="props">
    <w:spacing w:line="{letex:length-to-unitless-twip(.)}"/>
  </xsl:template>
  
  <xsl:template match="@css:text-align" mode="props tblPr">
    <w:jc w:val="{if (. = 'justify') then 'both' else .}"/>
  </xsl:template>
  
  <xsl:template match="@css:text-indent" mode="props">
    <xsl:variable name="twips" as="xs:integer" select="xs:integer(round(letex:length-to-unitless-twip(.)))"/>
    <w:ind>
      <xsl:choose>
        <!-- dunno whether this is correct. -->
        <xsl:when test="$twips lt 0">
          <xsl:attribute name="w:hanging" select="-1 * $twips"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="w:firstLine" select="-1 * $twips"/>
        </xsl:otherwise>
      </xsl:choose>
    </w:ind>
  </xsl:template>
  
  <xsl:template match="@css:page-break-before" mode="props">
    <xsl:if test="not(.='avoid')">
      <w:pageBreakBefore/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@css:page-break-after" mode="props">
    <xsl:if test=".='avoid'">
      <w:keepNext/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@css:page-break-inside" mode="props">
    <xsl:if test=".='avoid'">
      <w:keepLines/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="@css:orphans | @css:widows" mode="props">
    <xsl:if test="xs:integer(.) gt 1">
      <w:widowControl/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="w:pStyle" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="0"/>
  </xsl:template>
  
  <xsl:template match="w:keepNext" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="5"/>
  </xsl:template>
  
  <xsl:template match="w:keepLines" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="10"/>
  </xsl:template>
  
  <xsl:template match="w:pageBreakBefore" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="15"/>
  </xsl:template>
  
  <xsl:template match="w:widowControl" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="20"/>
  </xsl:template>
  
  <xsl:template match="w:spacing" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="25"/>
  </xsl:template>
  
  <xsl:template match="w:ind" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="30"/>
  </xsl:template>

  <xsl:template match="w:jc" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="35"/>
  </xsl:template>
  
</xsl:stylesheet>

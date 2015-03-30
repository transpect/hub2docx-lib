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
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:docx2hub      = "http://www.le-tex.de/namespace/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink css o w m wp r docx2hub"
>

  <xsl:key name="styleId" match="w:style" use="@w:styleId"/>

  <xsl:variable name="docx-template" as="element(w:root)"
    select="collection()/w:root"/>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- See also lists.xsl (preprocesses paras that contain lists)
       -->

  <xsl:template name="hub:pPr" as="element(w:pPr)?">
    <xsl:param name="default-pPrs" as="element(*)*" tunnel="yes"/>
    <xsl:variable name="unsorted" as="element(*)*">
      <xsl:apply-templates select="@css:page-break-after, 
                                   @css:page-break-inside, 
                                   @role, 
                                   @css:page-break-before, 
                                   (@css:widows, @css:orphans)[1], 
                                   @css:background-color,
                                   @css:margin-bottom, 
                                   @css:margin-top, 
                                   @css:line-height,
                                   @css:text-align" mode="props" />
      <xsl:call-template name="w:ind"/>      
      <xsl:sequence select="letex:borders(.)"/>
    </xsl:variable>
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:perform-sort>
        <xsl:sort data-type="number" order="ascending">
          <xsl:apply-templates select="." mode="letex:propsortkey"/>
        </xsl:sort>
        <xsl:sequence select="$unsorted"/>
        <xsl:sequence select="$default-pPrs[not(name() = $unsorted/name())]"/>
      </xsl:perform-sort>
    </xsl:variable>
    <xsl:if  test="$pPr">
      <w:pPr>
        <xsl:sequence  select="$pPr" />
      </w:pPr>
    </xsl:if>
  </xsl:template>

  <xsl:template  match="para[ not( parent::listitem) ] | simpara[not(parent::footnote)]"  mode="hub:default">
    <w:p origin="{if(self::para) then 'default_p_parentnotlistitem' else 'default_simpara'}">
      <xsl:call-template name="hub:pPr"/>
      <xsl:if test="@xml:id">
        <w:bookmarkStart w:id="{generate-id()}"  w:name="bm_{generate-id(.)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current"/>
      <xsl:if test="@xml:id">
        <w:bookmarkEnd w:id="{generate-id()}"/>
      </xsl:if>
      <xsl:if test="@css:page-break-after = 'always'">
        <w:r>
          <w:br w:type="page"/>
        </w:r>
      </xsl:if>
    </w:p>
  </xsl:template>

  <xsl:template  match="para[ parent::blockquote ]"  mode="hub:default" priority="2">
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:apply-templates  select="@css:page-break-after, @css:page-break-inside, @role, @css:page-break-before, @css:text-indent, (@css:widows, @css:orphans)[1], @css:margin-bottom, @css:margin-top, @css:line-height, @css:text-align"  mode="props" />
      <w:pStyle w:val="BlockText"/>
    </xsl:variable>
    <w:p origin="default_p_parentblockq">
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

  <xsl:template match="@role[. = 'ttt:token']" mode="props"/>
    
  <xsl:template match="@role" mode="props">
    <xsl:variable name="rule-in-source" select="key('style-by-name', .)" as="element(css:rule)?"/>
    <xsl:variable name="role-in-template" select="key('styleId', ., $docx-template)" as="element(w:style)?"/>
    <xsl:variable name="parent-is-para" select="boolean(parent::para or parent::simpara)" as="xs:boolean"/>
    <xsl:variable name="parent-is-inline" select="boolean(parent::phrase or parent::emphasis)" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="exists($rule-in-source)">
        <xsl:variable name="elt-name" as="xs:string">
          <xsl:choose>
            <xsl:when test="$rule-in-source/@layout-type = 'inline'">
              <xsl:sequence select="'w:rStyle'"/>
            </xsl:when>
            <xsl:when test="$rule-in-source/@layout-type = 'para'">
              <xsl:sequence select="'w:pStyle'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="$parent-is-para">
                  <xsl:sequence select="'w:pStyle'"/>
                </xsl:when>
                <xsl:when test="$parent-is-inline">
                  <xsl:sequence select="'w:rStyle'"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:message><xsl:value-of select="name(parent::*), ' with content ', parent::*"/> not implemented as parent for @role="<xsl:value-of select="."/>"</xsl:message>
                  <xsl:sequence select="'implementMe'"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:element name="{$elt-name}">
          <xsl:attribute name="w:val" select="."/>
          <xsl:choose>
            <xsl:when test="$elt-name eq 'w:pStyle' and $role-in-template/@w:type eq 'paragraph'">
              <xsl:attribute name="hub:para-role-in-template" select="'yes'"/>
            </xsl:when>
            <xsl:when test="$elt-name eq 'w:rStyle' and $role-in-template/@w:type eq 'character'">
              <xsl:attribute name="hub:inline-role-in-template" select="'yes'"/>
            </xsl:when>
          </xsl:choose>
        </xsl:element>
      </xsl:when>
      <!-- para not defined with css:rule but role exists in template-->
      <xsl:when test="$parent-is-para and $role-in-template/@w:type eq 'paragraph'">
        <w:pStyle w:val="{.}" hub:para-role-in-template="yes"/>
      </xsl:when>
      <!-- inline role not defined in css:rule but exists in template-->
      <xsl:when test="$parent-is-inline and $role-in-template/@w:type eq 'character'">
        <w:rStyle w:val="{.}" hub:inline-role-in-template="yes"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'para.xsl, match=@role: no style for role ', string(.)"/>
        <xsl:variable name="elt-name">
          <xsl:choose>
            <xsl:when test="$parent-is-para">
              <xsl:sequence select="'w:pStyle'"/>
            </xsl:when>
            <xsl:when test="$parent-is-inline">
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
    <w:spacing>
      <xsl:choose>
        <xsl:when test="matches(.,'pt$')">
          <xsl:attribute name="w:line" select="letex:length-to-unitless-twip(.)"/>
          <xsl:attribute name="w:lineRule" select="'atLeast'"/>
        </xsl:when>
        <xsl:when test="matches(.,'^[0-9\.]+$')">
          <xsl:attribute name="w:line" select="number(.) * 240"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="w:line" select="letex:length-to-unitless-twip(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </w:spacing>
  </xsl:template>
  
  <xsl:template match="@css:text-align" mode="props tblPr">
    <w:jc w:val="{if (. = 'justify') then 'both' else .}"/>
  </xsl:template>
  
  <xsl:template name="w:ind">
    <xsl:variable name="atts" as="attribute(*)*">
      <xsl:apply-templates select="@css:text-indent | @css:margin-left | @css:margin-right" mode="props"/>
    </xsl:variable>
    <xsl:if test="exists($atts)">
      <w:ind>
        <xsl:sequence select="$atts"/>
      </w:ind>  
    </xsl:if>    
  </xsl:template>

  <xsl:template match="@css:text-indent" mode="props">
    <xsl:variable name="indent" as="xs:integer" select="xs:integer(round(letex:length-to-unitless-twip(.)))"/>  
    <xsl:choose>
      <xsl:when test="$indent lt 0">
        <xsl:attribute name="w:hanging" select="-1 * $indent"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="w:firstLine" select="$indent"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="@css:margin-left | @css:margin-right" mode="props">
    <xsl:attribute name="w:{replace(local-name(), 'margin-', '')}" 
      select="xs:integer(round(letex:length-to-unitless-twip(.)))"></xsl:attribute>
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

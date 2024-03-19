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
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:docx2hub      = "http://transpect.io/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:mml = "http://www.w3.org/1998/Math/MathML"
    xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink css o w m wp r docx2hub mml"
>

  <xsl:key name="styleId" match="w:style" use="@w:styleId"/>

  <xsl:variable name="docx-template" as="element(w:root)"
    select="collection($collection-uri)/w:root"/>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- See also lists.xsl (preprocesses paras that contain lists)
       -->

  <xsl:template name="hub:pPr">
    <xsl:param name="default-pPrs" as="element(*)*" tunnel="yes"/>
    <xsl:variable name="unsorted" as="element(*)*">
      <xsl:apply-templates select="@css:page-break-after, 
                                   @css:page-break-inside, 
                                   @css:page-break-before[not(parent::para/parent::entry[not(ancestor::thead)])], 
                                   (@css:widows, @css:orphans)[1], 
                                   @css:background-color,
                                   @css:margin-bottom, 
                                   @css:margin-top, 
                                   @css:line-height,
                                   (@css:text-align, ancestor-or-self::entry[@align][1]/@align)[1], 
                                   ancestor-or-self::entry[@char][1]/@char" mode="props" />
      <xsl:call-template name="w:ind"/>
      <!-- will typically handle @role (or create a style if no @role is present / depending on context) -->
      <xsl:apply-templates select="." mode="hub:style-name"/>
      <xsl:apply-templates select="tabs" mode="hub:tabs"/>
      <xsl:sequence select="tr:borders(.)"/>
      <xsl:if test="empty(parent::biblioentry | parent::listitem)
                    and exists(phrase[@role = 'hub:identifier'][following-sibling::*[1]/self::tab])
                    and exists(key('styleId', @role, $docx-template)/w:pPr/w:numPr)">
        <!-- Explicit numbering in a para that has numbering properties but is not contained in a proper list -->
        <w:numPr>
<!--          <w:ilvl w:val="0"/>-->
          <w:numId w:val="0"/>
        </w:numPr>
        <xsl:copy-of select="key('styleId', @role, $docx-template)/w:pPr/w:ind"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="rPr">
      <xsl:if test="@css:color, 
        @css:font-size, 
        @css:font-weight, 
        @css:font-style, 
        @css:font-family, 
        @css:text-transform">
        <w:rPr>
          <xsl:apply-templates select="@css:color, 
            @css:font-size, 
            @css:font-weight, 
            @css:font-style, 
            @css:font-family, 
            @css:text-transform"  mode="props"/>
        </w:rPr>        
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:perform-sort>
        <xsl:sort data-type="number" order="ascending">
          <xsl:apply-templates select="." mode="tr:propsortkey"/>
        </xsl:sort>
        <xsl:sequence select="$unsorted"/>
        <xsl:sequence select="$default-pPrs[not(name() = $unsorted/name())]"/>
      </xsl:perform-sort>
    </xsl:variable>
    <xsl:if test="$pPr or $rPr">
      <w:pPr>
        <xsl:sequence  select="$pPr, $rPr" />
      </w:pPr>
    </xsl:if>
    <!--<xsl:if test="@css:page-break-before[parent::para/parent::entry[not(ancestor::thead)]]">
      <w:r>
        <w:br w:type="page"/>
      </w:r>
    </xsl:if>-->
  </xsl:template>
  
  <xsl:template match="tabs" mode="hub:tabs">
    <xsl:if test="tab">
      <w:tabs>
        <xsl:apply-templates mode="#current"/>
      </w:tabs>  
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="tab" mode="hub:tabs">
    <w:tab>
      <xsl:apply-templates select="@*" mode="#current"/>
    </w:tab>
  </xsl:template>
  
  <xsl:template match="tab/@horizontal-position" mode="hub:tabs">
    <xsl:attribute name="w:pos" select="tr:length-to-unitless-twip(.)"/>
  </xsl:template>
  
  <xsl:template match="tab/@align" mode="hub:tabs">
    <xsl:attribute name="w:val" select="."/>
  </xsl:template>

  <xsl:template match="tab/@leader" mode="hub:tabs">
    <xsl:attribute name="w:leader" select="."/>
  </xsl:template>
  
  <xsl:template match="tab/@xml:lang" mode="hub:tabs">
    <!-- GI 2023-01-16: noticed while debugging https://github.com/basex-gmbh/voktool-LingSoft/issues/334
         I think that @xml:lang on tab is meaningless. Why is it created by docx2hub in the first place? -->
  </xsl:template>
  
  <xsl:template match="tab/@*" mode="hub:tabs" priority="-1">
    <xsl:if test="$debug eq 'yes'">
      <xsl:message select="'attribute not mapped:', name()"/>
    </xsl:if>
  </xsl:template>

  <!-- overwrite me -->
  <xsl:template match="*" mode="hub:style-name">
    <xsl:apply-templates select="@role" mode="props"/>
  </xsl:template>

  <!-- overwrite me -->
  <xsl:template match="authorgroup" mode="hub:default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>
  
  <xsl:template name="create-para" match="para[ not( parent::listitem) ] | author[parent::authorgroup] | simpara[not(parent::footnote)] | attribution"  mode="hub:default">
    <w:p origin="{if(self::para) then 'default_p_parentnotlistitem' else if(self::simpara) then 'default_simpara' else local-name()}">
      <xsl:apply-templates select="anchor[@role=('w14:paraId','w14:textId')]" mode="#current"/>
      <xsl:call-template name="hub:pPr"/>
      <xsl:apply-templates select="@xml:id" mode="hub:bookmark-start"/>
      <xsl:variable name="content" as="node()*">
        <xsl:apply-templates  select="node() except anchor[@role=('w14:paraId','w14:textId')]"  mode="#current">
          <xsl:with-param name="rPrContent" as="element(*)*" tunnel="yes">
             <xsl:apply-templates select="@css:color, 
                                          @css:background-color,
                                          @css:font-size, 
                                          @css:font-weight, 
                                          @css:font-style, 
                                          @css:font-family, 
                                          @css:text-transform"  mode="props"/>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="parent::entry 
                        and (exists(node())
                             and 
                             (
                               every $n in node() 
                               satisfies ($n/(self::equation, self::inlineequation)
                                         and 
                                         (exists($n/node())
                                          and 
                                          (
                                            every $m in $n/node() 
                                            satisfies ($m/self::mml:math)
                                          )
                                         )
                                       )
                             )
                            )">
          <m:oMathPara>
            <m:oMathParaPr>
              <m:jc m:val="{(((equation, inlineequation)/@css:text-align), @css:text-align, parent::*/@align, 'center')[1]}"/>
            </m:oMathParaPr>
            <xsl:choose>
              <xsl:when test="$content[self::m:oMathPara]">
                <xsl:sequence select="$content/node()"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="$content"/>
              </xsl:otherwise>
            </xsl:choose>
          </m:oMathPara>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$content"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="@xml:id" mode="hub:bookmark-end"/>
      <xsl:if test="@css:page-break-after = 'always'">
        <w:r>
          <w:br w:type="page"/>
        </w:r>
      </xsl:if>
    </w:p>
  </xsl:template>

  <xsl:template match="para[parent::blockquote][not(@role)]" mode="hub:style-name">
    <w:pStyle w:val="BlockText"/>
  </xsl:template>

  <xsl:template  match="caption"  mode="hub:default" priority="-1">
    <xsl:apply-templates  select="*"  mode="#current"/>
  </xsl:template>

  <xsl:template match="@role[. = 'ttt:token']" mode="props"/>
    
  <xsl:template match="@role" mode="props">
    <xsl:variable name="root" as="document-node()?" select="root(.)[. instance of document-node()]"/>
    <xsl:variable name="rule-in-source" as="element(css:rule)?">
      <xsl:if test="count($root/*) = 1">
        <xsl:sequence select="key('style-by-name', .)[1]"></xsl:sequence>
      </xsl:if>
    </xsl:variable>
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
            <xsl:when test="$parent-is-para or parent::title">
              <xsl:sequence select="'w:pStyle'"/>
            </xsl:when>
            <xsl:when test="$parent-is-inline">
              <xsl:sequence select="'w:rStyle'"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:message>Element <xsl:value-of select="name(parent::*)"/> not implemented as parent for @role="<xsl:value-of select="."/>"</xsl:message>
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
    <w:spacing w:after="{tr:length-to-unitless-twip(.)}"/>
  </xsl:template>
  
  <xsl:template match="@css:margin-top" mode="props">
    <w:spacing w:before="{tr:length-to-unitless-twip(.)}"/>
  </xsl:template>
  
  <xsl:template match="@css:line-height" mode="props">
    <w:spacing>
      <xsl:choose>
        <xsl:when test="matches(.,'pt$')">
          <xsl:attribute name="w:line" select="tr:length-to-unitless-twip(.)"/>
          <xsl:attribute name="w:lineRule" select="'atLeast'"/>
        </xsl:when>
        <xsl:when test="matches(.,'^[0-9\.]+$')">
          <xsl:attribute name="w:line" select="number(.) * 240"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="w:line" select="tr:length-to-unitless-twip(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </w:spacing>
  </xsl:template>
  
  <!-- not implemented, yet -->
  <xsl:template match="@align[. eq 'char']" mode="props tblPr"/>
  
  <xsl:template match="@css:text-align | @align" mode="props tblPr">
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
    <xsl:variable name="indent" as="xs:integer" select="xs:integer(round(tr:length-to-unitless-twip(.)))"/>  
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
      select="xs:integer(round(tr:length-to-unitless-twip(.)))"></xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@css:page-break-before" mode="props">
    <xsl:if test="not(.=('avoid','auto'))">
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

  <xsl:template match="w:pStyle" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="0"/>
  </xsl:template>
  
  <xsl:template match="w:keepNext" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="5"/>
  </xsl:template>
  
  <xsl:template match="w:keepLines" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="10"/>
  </xsl:template>
  
  <xsl:template match="w:pageBreakBefore" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="15"/>
  </xsl:template>
  
  <xsl:template match="w:widowControl" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="20"/>
  </xsl:template>
  
  <xsl:template match="w:spacing" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="25"/>
  </xsl:template>
  
  <xsl:template match="w:ind" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="30"/>
  </xsl:template>

  <xsl:template match="w:jc" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="35"/>
  </xsl:template>
  
    <xsl:template match="w:rStyle" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="-10"/>
  </xsl:template>

  <xsl:template match="w:rFonts" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="10"/>
  </xsl:template>

  <xsl:template match="w:b" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="20"/>
  </xsl:template>

  <xsl:template match="w:i" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="30"/>
  </xsl:template>

  <xsl:template match="w:caps" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="40"/>
  </xsl:template>
  
  <xsl:template match="w:color" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="100"/>
  </xsl:template>

  <xsl:template match="w:position" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="105"/>
  </xsl:template>

  <xsl:template match="w:u" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="115"/>
  </xsl:template>
  
  <xsl:template match="w:sz" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="110"/>
  </xsl:template>
  
  <xsl:template match="w:shd" mode="tr:propsortkey" as="xs:integer">
    <xsl:sequence select="143"/>
  </xsl:template>
  
  <xsl:template match="w:p/w:p" mode="hub:clean">
    <xsl:apply-templates select="node() except w:pPr" mode="#current"/>
  </xsl:template>
  
</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:letex		= "http://www.le-tex.de/namespace"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://www.le-tex.de/namespace/hub"
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub dbk xlink o w m wp r css"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- named templates -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- The concept for determination of the proper w:rPr (run properties) for a w:r (text run) is as follows:
        * each ancestor element, which imposes a certain rPr-content for its text content, adds this to the tunneling parameter rPrContent
        * whenever a w:r is created, it uses the rPrContent as w:rPr-content
       There is only one problem left: some runProperties may be mutually exclusive or toggle properties.
       This cases are dealt with by this template, which therefore should be called every time when the tunneled rPrContent is to be modified.
       -->
  <xsl:template  name="mergeRunProperties" as="element(*)*">
    <xsl:param  name="inherited_rPrContent"  as="element(*)*"/><!-- w:… property elements -->
    <xsl:param  name="new_rPrContent"        as="element(*)*"/><!-- w:… property elements -->

    <!-- § Attention: the following code may not correctly deal with all possible cases. Currently supported are:
           * nested sub-/superscript (not solved, but raises an error)
         -->
    <xsl:variable  name="dumbMergedRunProperties"  select="$inherited_rPrContent | $new_rPrContent" as="element(*)*"/>
    <xsl:for-each select="$dumbMergedRunProperties">
      <xsl:sort data-type="number" order="ascending">
        <xsl:apply-templates select="." mode="letex:propsortkey"/>
      </xsl:sort>
      <xsl:choose>
        <!-- DEMO for a toggling property -->
        <xsl:when test="self::w:XXX">
          <!-- only the first occurence needs to be accounted for, since it accounts for all other occurences -->
          <xsl:if test=". is ($dumbMergedRunProperties//*[name() eq current()/name()])[1]">
            <!-- toggling means to purge the property, if it is given twice -->
            <xsl:if test="count( $dumbMergedRunProperties//*[name() eq current()/name()]) eq 1">
              <xsl:copy-of select="."/>
            </xsl:if>
          </xsl:if>
        </xsl:when>
        <!-- mutually exclusive or otherwise combining properties -->
        <xsl:when test="count( $dumbMergedRunProperties//*[name() = ( 'w:subscript' , 'w:superscript' )]) gt 1">
          <xsl:message terminate="yes"
            select="'ERROR: the combination or nesting of subscript/superscript is currently not supported.'"/>
        </xsl:when>
        <!-- all other properties, which we do not deal with here -->
        <xsl:otherwise>
          <xsl:copy-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- in some context text()-nodes generate a w:r (because the parent-node has not done it yet), in all other cases text()-nodes will be copied by a catch anything rule -->
  <xsl:template  match="  text()
                        | phrase[@role eq 'hub:ooxml-symbol'][@css:font-family][@annotations]
                        | phrase[@role eq 'hub:foreign']"  mode="hub:default">
    <xsl:param  name="rPrContent" as="element(*)*" tunnel="yes"/>
    <w:r>
      <xsl:if  test="$rPrContent">
        <w:rPr>
          <xsl:sequence  select="$rPrContent"/>
        </w:rPr>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="self::phrase[@role eq 'hub:ooxml-symbol']">
          <w:sym w:font="{@css:font-family}" w:char="{@annotations}"/>      
        </xsl:when>
        <xsl:when test="self::phrase[@role eq 'hub:foreign']">
          <xsl:apply-templates mode="hub:foreign"/>      
        </xsl:when>
        <xsl:otherwise>
          <w:t>
            <xsl:if  test="matches( . , '^\s|\s$')">
              <xsl:attribute  name="xml:space"  select="'preserve'"/>
            </xsl:if>
            <xsl:value-of select="."/>
            <!-- We don’t use xml:space="preserve" in Hub. All space must be preserved. 
              <xsl:choose>
              <xsl:when test="ancestor::*[@xml:space][1]/@xml:space eq 'preserve'">
                <xsl:value-of select="."/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="replace(., '\s+', ' ')"/>
              </xsl:otherwise>
            </xsl:choose>-->
          </w:t>    
        </xsl:otherwise>
      </xsl:choose>
    </w:r>
  </xsl:template>

  <xsl:template  match="text()[matches( . , '^\s+$')][not(ancestor::para or ancestor::title)]" />

  <xsl:template  match="text()"  mode="hub:default" priority="-10000">
    <xsl:param  name="rPrContent"  as="element(*)*" tunnel="yes"/>
    <w:r>
      <xsl:if  test="$rPrContent">
        <w:rPr>
          <xsl:sequence  select="$rPrContent"/>
        </w:rPr>
      </xsl:if>
      <w:t>
        <xsl:if  test="matches( . , '^\s|\s$')">
          <xsl:attribute  name="xml:space"  select="'preserve'"/>
        </xsl:if>
        <xsl:value-of  select="." />
      </w:t>
    </w:r>
  </xsl:template>

  <xsl:template match="w:r[not(parent::w:p)]" mode="remove-misplaced-runs" priority="3000">
    <xsl:message>HURZ
    </xsl:message>
  </xsl:template>


  <xsl:template  match="alt"  mode="hub:default">
    <xsl:message>Implement me: alt (in text-runs.xsl)
    </xsl:message>
  </xsl:template>

  <xsl:template  match="br"  mode="hub:default" priority="2">
    <xsl:choose>
      <xsl:when test="parent::para or parent::emphasis or parent::phrase">
        <w:r>
          <w:br/>
        </w:r>
      </xsl:when>
      <xsl:otherwise>
        <w:br/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template  match="emphasis | phrase"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="element(*)*"  tunnel="yes"/><!-- w:… property elements -->
    <xsl:apply-templates mode="#current" >
      <xsl:with-param  name="rPrContent"  tunnel="yes" as="element(*)*"><!-- w:… property elements -->
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"  as="element(*)*"/>
          <xsl:with-param name="new_rPrContent" as="element(*)*">
            <xsl:apply-templates select="@role, @css:*, @xml:lang" mode="props"/>
            <xsl:sequence select="letex:borders(.)"/>
            <xsl:if test="not(@role) and self::emphasis">
              <xsl:message
                select="concat( 'Warning: missing role attribute for element ', name(), ' - falling back to &quot;italic&quot;' )"/>
              <w:i/>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template  match="subscript | superscript"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="element(*)*" tunnel="yes"/>
    <xsl:apply-templates  select="node()"  mode="#current">
      <xsl:with-param  name="rPrContent"  tunnel="yes" as="element(*)*">
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent" as="element(*)*"/>
          <xsl:with-param  name="new_rPrContent" as="element(w:vertAlign)">
            <w:vertAlign w:val="{ if ( self::subscript )
                                  then 'subscript'
                                  else if ( self::superscript )
                                       then 'superscript'
                                       else error( (), concat( 'Internal ERROR: expected subscript or superscript, but got ', self::*/local-name()))
                                }"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="@css:font-family" mode="props">
    <w:rFonts w:ascii="{.}" w:hAnsi="{.}"/>
  </xsl:template>

  <xsl:template match="@css:font-style[. = ('italic', 'oblique')]" mode="props">
    <w:i/>
  </xsl:template>
  <xsl:template match="@css:font-style[. = ('normal')]" mode="props">
    <w:i w:val="0"/>
  </xsl:template>

  <xsl:template match="@css:font-weight[matches(., '^(bold|[6-9]00)$')]" mode="props">
    <w:b/>
  </xsl:template>
  <xsl:template match="@css:font-weight[matches(., '^(normal|[45]00)$')]" mode="props">
    <w:b w:val="0"/>
  </xsl:template>

  <xsl:template match="@css:font-variant[. = 'small-caps']" mode="props">
    <w:smallCaps w:val="true"/>
  </xsl:template>

  <xsl:template match="@css:text-decoration-line[. eq 'underline']" mode="props" as="element(w:u)">
    <w:u w:val="single">
      <xsl:apply-templates select="../@css:text-decoration-color" mode="props-secondary"/>
      <xsl:apply-templates select="../@css:text-decoration-style" mode="props-secondary"/>
    </w:u>
  </xsl:template>
  <xsl:template match="@css:text-decoration-color" mode="props-secondary">
    <xsl:attribute name="w:color" select="substring(letex:convert-css-color(., 'hex'), 2, 6)"/>
  </xsl:template>
  <xsl:template match="@css:text-decoration-style" mode="props-secondary">
    <xsl:attribute name="w:val" select=" letex:border-style(.)"/>
  </xsl:template>
  
  <xsl:template match="@css:text-decoration-color" mode="props"/>
  <xsl:template match="@css:text-decoration-style" mode="props"/>
  
  <xsl:template match="@css:text-decoration-line[. eq 'line-through']" mode="props">
    <w:strike w:val="on" />
  </xsl:template>
  
  <xsl:template match="@css:background-color" mode="props">
    <w:shd w:fill="{substring(letex:convert-css-color(., 'hex'), 2, 6)}" w:val="clear"/>
  </xsl:template>

  <xsl:template match="@css:*[starts-with(local-name(), 'border-')]" mode="props"/>

  <xsl:template match="@css:font-size" mode="props">
    <w:sz w:val="{round(letex:length-to-unitless-twip(.) idiv 10)}"/>
  </xsl:template>
  
  <xsl:template match="@css:color" mode="props">
    <w:color w:val="{substring(letex:convert-css-color(., 'hex'), 2, 6)}"/>
  </xsl:template>
  
  <xsl:template match="@css:text-transform[. = 'uppercase']" mode="props">
    <w:caps/>
  </xsl:template>
  
  <xsl:template match="@xml:lang[normalize-space(.)]" mode="props">
    <w:lang w:val="{.}"/>
  </xsl:template>

  <xsl:template match="@*" mode="props">
    <xsl:message>Unimplemented in mode props: <xsl:value-of select="name()"/>=<xsl:value-of select="."/></xsl:message>
  </xsl:template>
  
  <xsl:key name="style-by-name" match="css:rule" use="@name"/>
  
  <xsl:function name="letex:borders" as="element()*">
    <xsl:param name="elt" as="element(*)"/>
    <xsl:variable name="targetName" as="xs:string">
      <xsl:choose>
        <xsl:when test="local-name($elt) = ('phrase', 'emphasis')">
          <xsl:sequence select="'w:bdr'"/>
        </xsl:when>
        <xsl:when test="local-name($elt) = ('entry')">
          <xsl:sequence select="'w:tcBorders'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="'w:pBdr'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="cssattribs" as="attribute()*" select="$elt/@css:*[starts-with(local-name(), 'border-')]"/>
    <xsl:if test="exists($cssattribs)">
      <xsl:variable name="styles" select="$cssattribs[ends-with(local-name(), 'style')]" as="attribute()*"/>
      <xsl:variable name="widths" select="$cssattribs[ends-with(local-name(), 'width')]" as="attribute()*"/>
      <xsl:variable name="colors" select="$cssattribs[ends-with(local-name(), 'color')]" as="attribute()*"/>
      <xsl:variable name="all-same" as="xs:boolean"
        select="count($styles) = 4 and count($widths) = 4 and count($colors) = (0, 4)
                and not($styles[1] = 'none')
                and count(distinct-values($styles)) = 1 and count(distinct-values($widths)) = 1 and count(distinct-values($colors)) = (0, 1)"/>
      <xsl:element name="{$targetName}">
        <xsl:choose>
          <xsl:when test="$all-same and not($targetName = 'w:tcBorders')">
            <xsl:attribute name="w:val" select="letex:border-style($styles[1])"/>
            <xsl:attribute name="w:sz" select="letex:length-to-border-width-type($widths[1])"/>
            <xsl:attribute name="w:space" select="letex:length-to-unitless-twip(($elt/@css:margin-top, '0pt')[1])"/>
            <xsl:attribute name="w:color" select="if ($colors) then substring(letex:convert-css-color($colors[1], 'hex'), 2, 6) else 'auto'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:for-each select="('top', 'left', 'bottom', 'right')">
              <xsl:apply-templates select="$cssattribs[local-name() = concat('border-', current(), '-style')]"
                mode="props-secondary">
                <xsl:with-param name="width" select="$cssattribs[local-name() = concat('border-', current(), '-width')]"/>
                <xsl:with-param name="color" select="$cssattribs[local-name() = concat('border-', current(), '-color')]"/>
                <xsl:with-param name="targetName" select="$targetName"/>
              </xsl:apply-templates>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <xsl:template match="@css:border-top-style | @css:border-bottom-style | @css:border-left-style | @css:border-right-style" mode="props-secondary">
    <xsl:param name="width" as="attribute()?"/>
    <xsl:param name="color" as="attribute()?"/>
    <xsl:param name="targetName"/>
    <xsl:choose>
      <xsl:when test="$targetName = 'w:tcBorders'">
        <xsl:element name="w:{replace(local-name(), 'border-(.+)-style', '$1')}">
          <xsl:attribute name="w:val" select="letex:border-style(.)"/>
          <xsl:apply-templates select="$width, $color" mode="#current"/>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="@css:border-top-width | @css:border-bottom-width | @css:border-left-width | @css:border-right-width" mode="props-secondary">
    <xsl:attribute name="w:sz" select="letex:length-to-border-width-type(.)"/>
  </xsl:template>

  <xsl:template match="@css:border-top-color | @css:border-bottom-color | @css:border-left-color | @css:border-right-color" mode="props-secondary">
    <xsl:attribute name="w:color" select="substring(letex:convert-css-color(., 'hex'), 2, 6)"/>
  </xsl:template>
  
  <xsl:function name="letex:border-style" as="xs:string">
    <xsl:param name="style-val" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$style-val eq 'solid'">
        <xsl:sequence select="'single'"/>
      </xsl:when>
      <xsl:when test="$style-val eq 'dotted'">
        <xsl:sequence select="'dotted'"/>
      </xsl:when>
      <xsl:when test="$style-val eq 'dashed'">
        <xsl:sequence select="'dash'"/>
      </xsl:when>
      <xsl:when test="$style-val eq 'double'">
        <xsl:sequence select="'double'"/>
      </xsl:when>
      <xsl:when test="$style-val = ('none', 'hidden')">
        <xsl:sequence select="'none'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'single'"/>
        <xsl:message
          select="'Border style: unimplemented value', $style-val, ' – falling back to solid.'"
        />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="w:rStyle" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="-10"/>
  </xsl:template>

  <xsl:template match="w:rFonts" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="10"/>
  </xsl:template>

  <xsl:template match="w:b" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="20"/>
  </xsl:template>

  <xsl:template match="w:i" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="30"/>
  </xsl:template>

  <xsl:template match="w:caps" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="40"/>
  </xsl:template>
  
  <xsl:template match="w:color" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="100"/>
  </xsl:template>

  <xsl:template match="w:u" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="115"/>
  </xsl:template>
  
  <xsl:template match="w:sz" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="110"/>
  </xsl:template>
  
  <xsl:template match="w:shd" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="120"/>
  </xsl:template>

  
  
  
  <xsl:template  match="@css:*"  mode="hub:default">
    <xsl:copy />
  </xsl:template>

  <xsl:template  match="dbk:tabs"  mode="hub:default" />
  <xsl:template  match="dbk:tab"  mode="hub:default">
    <w:r>
      <w:tab/>
    </w:r>
  </xsl:template>

  <!-- The innermost / last style wins when something is derived from nested phrases: -->
  
  <xsl:template match="w:rPr/*[following-sibling::*[name() = name(current())]]" mode="hub:clean"/>

  <!-- consolidate (also pPr). Example:
           <w:pPr>
            <w:spacing w:after="130"/>
            <w:spacing w:before="130"/>
         </w:pPr>
         →
-->
  <xsl:template match="w:pPr | w:rPr | w:tcPr | w:tblPr" mode="hub:clean">
    <xsl:variable name="cleaned-props" as="element(*)*">
      <xsl:apply-templates mode="#current"/>
    </xsl:variable>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="$cleaned-props" group-by="name()">
        <xsl:copy copy-namespaces="no">
          <xsl:sequence select="current-group()/@*, current-group()/node()"/>
        </xsl:copy>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

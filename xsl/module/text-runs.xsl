<?xml version="1.0" encoding="UTF-8"?>

<!--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~     Authors: Gerrit Imsieke, Ralph Krüger                                                                             ~
~              (C) le-tex publishing services GmbH Leipzig (2010)                                                       ~
~                                                                                                                       ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

<!DOCTYPE xsl:stylesheet
  [
    <!-- obsolete? -->
    <!ENTITY RunCreators				"*[ local-name() = ( 'emphasis' , 'link' ) ]" >
  ]
>

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
  <xsl:template  name="mergeRunProperties">
    <xsl:param  name="inherited_rPrContent"  as="node()*"/>
    <xsl:param  name="new_rPrContent"        as="node()*"/>

    <!-- § Attention: the following code may not correctly deal with all possible cases. Currently supported are:
           * nested sub-/superscript (not solved, but raises an error)
         -->
    <xsl:variable  name="dumbMergedRunProperties"  select="$inherited_rPrContent | $new_rPrContent"/>
    <xsl:for-each  select="$dumbMergedRunProperties">
      <xsl:choose>
        <!-- DEMO for a toggling property -->
        <xsl:when  test="self::w:XXX">
          <!-- only the first occurence needs to be accounted for, since it accounts for all other occurences -->
          <xsl:if  test=". is ($dumbMergedRunProperties//*[name() eq current()/name()])[1]">
            <!-- toggling means to purge the property, if it is given twice -->
            <xsl:if  test="count( $dumbMergedRunProperties//*[name() eq current()/name()]) eq 1">
              <xsl:copy-of  select="."/>
            </xsl:if>
          </xsl:if>
        </xsl:when>
        <!-- mutually exclusive or otherwise combining properties -->
        <xsl:when  test="count( $dumbMergedRunProperties//*[name() = ( 'w:subscript' , 'w:superscript' )]) gt 1">
          <xsl:message  terminate="yes"  select="'ERROR: the combination or nesting of subscript/superscript is currently not supported.'"/>
        </xsl:when>
        <!-- all other properties, which we do not deal with here -->
        <xsl:otherwise>
          <xsl:copy-of  select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- in some context text()-nodes generate a w:r (because the parent-node has not done it yet), in all other cases text()-nodes will be copied by a catch anything rule -->
  <xsl:template  match="text()"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
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
        <!-- now explicit phrase role="br":
        <xsl:analyze-string  select="."  regex="&#x0A;">
          <xsl:matching-substring>
            <w:br/>
          </xsl:matching-substring>
          <xsl:non-matching-substring>
            <xsl:value-of  select="." />
          </xsl:non-matching-substring>
        </xsl:analyze-string>
        -->
        <xsl:choose>
          <xsl:when test="ancestor::*[@xml:space][1]/@xml:space eq 'preserve'">
            <xsl:value-of select="."/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="replace(., '\s+', ' ')"/>
          </xsl:otherwise>
        </xsl:choose>
      </w:t>
    </w:r>
  </xsl:template>

  <xsl:template  match="text()[matches( . , '^\s+$')][not(ancestor::para or ancestor::title)]" />

  <xsl:template  match="text()"  mode="hub:default" priority="-10000">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
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

  <xsl:template  match="phrase[@role eq 'br']"  mode="hub:default" priority="2">
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

  <!-- because of the transformation used to create the DocBook-document to be transformed now, emphasis does never contain anything else then a single textnode -->
  <!-- In the DocBook-data to be converted, I used the phrase element at places where emphasis would not be allowed. Currently, this is the only use of phrase.
       § If phrase is used otherwise in the future, the assumed analogy to emphasis does not stand further. -->
  <xsl:template  match="emphasis | phrase"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:variable name="role" select="@role" as="attribute(role)?"/>
    <xsl:apply-templates  select="node()"  mode="#current" >
      <xsl:with-param  name="rPrContent"  tunnel="yes">
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
          <xsl:with-param  name="new_rPrContent">
            <!-- §§ the combination of nested font properties may not suit the rendering expactions defined by the DocBook standard -->

            <xsl:choose>
              <xsl:when test="@css:* or
                              /hub/info/styles/inlinestyles/style[@role eq $role]/@css:* or
                              /hub/info/css:rules/css:rule[@layout-type eq 'inline'][@name eq $role]/@css:*">
                <hub:styles>
                  <!-- HUB version 1.0 -->
                  <xsl:sequence select="letex:resolve-text-props-by-css-attribs(
                                          /hub/info/styles/inlinestyles/style[@role eq $role]/@css:*,
                                          ()
                                        )"/>
                  <!-- HUB version 1.1 -->
                  <xsl:sequence select="letex:resolve-text-props-by-css-attribs(
                                          /hub/info/css:rules/css:rule[@layout-type eq 'inline'][@name eq $role]/@css:*,
                                          ()
                                        )"/>
                </hub:styles>
                <hub:deviations>
                  <xsl:sequence select="letex:resolve-text-props-by-css-attribs(
                                          /hub/info/styles/inlinestyles/style[@role eq $role]/@css:*, 
                                          @css:*
                                          )"/>
                  <xsl:sequence select="letex:resolve-text-props-by-css-attribs(
                                          /hub/info/css:rules/css:rule[@layout-type eq 'inline'][@name eq $role]/@css:*,
                                          @css:*
                                        )"/>
                </hub:deviations>
                <w:rStyle hub:val="{$role}"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="letex:resolve-text-props-by-role-name($role)"/>
              </xsl:otherwise>
            </xsl:choose>

            <xsl:if  test="not(@role) and self::emphasis">
              <xsl:message  select="concat( 'Warning: missing role attribute for element ', name(), ' - falling back to &quot;italic&quot;' )"/>
              <w:i/>
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template  match="subscript | superscript"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:apply-templates  select="node()"  mode="#current">
      <xsl:with-param  name="rPrContent"  tunnel="yes">
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
          <xsl:with-param  name="new_rPrContent">
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

  <xsl:function name="letex:resolve-text-props-by-css-attribs" as="element()*">
    <xsl:param name="css-style-attribs" as="attribute()*"/>
    <xsl:param name="css-deviation-attribs" as="attribute()*"/>
    <xsl:variable name="cssattribs" as="attribute()*" select="$css-deviation-attribs, $css-style-attribs[not(name() = (for $i in $css-deviation-attribs return name($i)))]"/>
    <!-- ever heard of xsl:apply-templates, dude? -->
    <xsl:for-each select="$cssattribs">
      <xsl:choose>
        <xsl:when test="local-name() eq 'font-family'">
          <w:rFonts w:ascii="{.}" w:hAnsi="{.}"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-style' and . = ('italic', 'oblique')">
          <w:i/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-style' and . = ('normal')">
          <w:i w:val="0"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-weight' and . = ('bold', '450', '500')">
          <w:b/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-weight' and . = ('normal')">
          <w:b w:val="0"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-size'">
          <xsl:apply-templates select="." mode="css2docx"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'text-transform'">
          <xsl:apply-templates select="." mode="css2docx"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'font-variant' and . = 'small-caps'">
          <w:smallCaps w:val="true"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'color'">
          <w:color w:val="{letex:retrieve-color-attribute-val(.)}"/>
        </xsl:when>
        <xsl:when test="local-name() eq 'text-decoration-line' and . eq 'underline'">
          <w:u w:val="single">
            <xsl:if test="$cssattribs[local-name() eq 'text-decoration-color']">
              <xsl:attribute name="w:color" select="letex:retrieve-color-attribute-val($cssattribs[local-name() eq 'text-decoration-color'])"/>
            </xsl:if>
          </w:u>
        </xsl:when>
        <xsl:when test="local-name() eq 'text-decoration-line' and . eq 'line-through'">
          <w:strike w:val="on" />
        </xsl:when>
        <xsl:when test="local-name() eq 'background-color'">
          <w:shd w:fill="{letex:retrieve-color-attribute-val(.)}" w:val="clear"/>
        </xsl:when>
        <!-- ignored css attributes (already handled above) -->
        <xsl:when test="matches(local-name(.), '^(border|text-decoration-([^l]))')" />
        <xsl:otherwise>
          <xsl:message select="'Text run: unimplemented css attribute', local-name(.), 'with value', xs:string(.)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <!-- border properties -->
    <xsl:if test="$cssattribs[matches(local-name(), '^border.*(width|style|color)$')][not(matches(., '^0+[^0]*$'))]">
      <xsl:if test="$cssattribs[matches(local-name(), 'border.(top|right|bottom|left).+$')]">
        <xsl:message select="'Border direction attribute: not implemented yet.'"/>
      </xsl:if>
      <xsl:variable name="borderstyle" as="xs:string?">
        <xsl:choose>
          <xsl:when test="$cssattribs[local-name() eq 'border-style'][. eq 'solid']">
            <xsl:sequence select="'single'"/>
          </xsl:when>
          <xsl:when test="$cssattribs[local-name() eq 'border-style'][. eq 'dotted']">
            <xsl:sequence select="'dotted'"/>
          </xsl:when>
          <xsl:when test="$cssattribs[local-name() eq 'border-style'][. eq 'dashed']">
            <xsl:sequence select="'dashed'"/>
          </xsl:when>
          <xsl:when test="$cssattribs[local-name() eq 'border-style'][. eq 'double']">
            <xsl:sequence select="'double'"/>
          </xsl:when>
          <xsl:when test="$cssattribs[local-name() eq 'border-style'][. = ('none', 'hidden')]">
            <xsl:sequence select="'none'"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="'single'"/>
            <xsl:message select="'Border style: unimplemented value', xs:string($cssattribs[local-name() eq 'border-style']), ' - falling back to solid.'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="borderwidth" as="xs:string?">
        <xsl:sequence select="if ($cssattribs[local-name() eq 'border-width'][matches(., 'pt$')]) 
                              then xs:string(xs:integer(replace($cssattribs[local-name() eq 'border-width'], '\s*pt$', '')) * 12) 
                              else '12'"/>
      </xsl:variable>
      <xsl:variable name="bordercolor" as="xs:string?">
        <xsl:choose>
          <xsl:when test="$cssattribs[local-name() eq 'border-color'][not(.='')]">
            <xsl:sequence select="letex:retrieve-color-attribute-val($cssattribs[local-name() eq 'border-color'])"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:sequence select="'auto'"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <w:bdr w:val="{$borderstyle}" w:sz="{$borderwidth}" w:space="0" w:color="{$bordercolor}"/>
    </xsl:if>
  </xsl:function>

  <xsl:template match="@css:font-size" mode="css2docx">
    <w:sz w:val="round(letex:length-to-unitless-twip(.) * 0.1)"/>
  </xsl:template>

  <xsl:template match="@css:text-transform[. = 'uppercase']" mode="css2docx">
    <w:caps/>
  </xsl:template>

  <xsl:template match="@*" mode="css2docx">
    <xsl:message>Unimplemented in mode css2docx: <xsl:value-of select="name()"/>=<xsl:value-of select="."/></xsl:message>
  </xsl:template>
  
  <xsl:function name="letex:resolve-text-props-by-role-name" as="element()*">
    <xsl:param name="role" as="xs:string"/>
    <xsl:for-each select="distinct-values(tokenize(lower-case($role), '&#x20;'))">
      <xsl:choose>
        <xsl:when  test=". = ( 'strong', 'bold' )">
          <w:b/>
        </xsl:when>
        <xsl:when  test=". = ( 'em', 'it', 'italic' )">
          <w:i/>
        </xsl:when>
        <xsl:when  test=". = ( 'italicstrong' , 'bolditalic' )">
          <w:b/>
          <w:i/>
        </xsl:when>
        <xsl:when  test=". = ( 'underline' )">
          <w:u w:val="single"/>
        </xsl:when>
        <xsl:when  test=". = ( 'smallcaps' )">
          <w:smallCaps  w:val="true"/>
        </xsl:when>
        <xsl:when  test=". = ( 'smallcapsstrong' )">
          <w:smallCaps  w:val="true"/>
          <w:b/>
        </xsl:when>
        <xsl:when  test=". = ( 'italicsmallcaps' )">
          <w:smallCaps  w:val="true"/>
          <w:i/>
        </xsl:when>
        <xsl:when test=". = 'antsblack'">
          <w:effect w:val="antsBlack"/><!-- builtin 'Black Dashed Line Animation' -->
        </xsl:when>
        <xsl:when test=". = 'antsred'">
          <w:effect w:val="antsRed"/><!-- builtin 'Marching Red Ants' -->
        </xsl:when>
        <xsl:when test=". = 'blinkbackground'">
          <w:effect w:val="blinkBackground"/><!-- builtin 'Blinking Background Animation' -->
        </xsl:when>
        <xsl:when test=". = 'noeffect'">
          <w:effect w:val="none"/>
        </xsl:when>
        <xsl:when  test=". eq 'br'" />
        <xsl:when  test=". eq 'pagebreakbefore'" />
        <xsl:otherwise>
          <w:rStyle hub:val="{$role}"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <xsl:template  match="@css:*"  mode="hub:default">
    <xsl:copy />
  </xsl:template>

  <xsl:template  match="dbk:tabs"  mode="hub:default" />
  <xsl:template  match="dbk:tab"  mode="hub:default">
    <w:r>
      <w:tab/>
    </w:r>
  </xsl:template>

</xsl:stylesheet>

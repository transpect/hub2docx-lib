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
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink o w m wp r"
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
        <xsl:value-of select="replace(., '\s+', ' ')"/>
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
    <xsl:apply-templates  select="node()"  mode="#current" >
      <xsl:with-param  name="rPrContent"  tunnel="yes">
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
          <xsl:with-param  name="new_rPrContent">
            <!-- §§ the combination of nested font properties may not suit the rendering expactions defined by the DocBook standard -->
            <xsl:choose>
              <xsl:when  test="@role = ( 'strong' , 'bold' , 'Bold' )">
                <w:b/>
              </xsl:when>
              <xsl:when  test="@role = ( 'em' , 'it' , 'italic' , 'Italic' )">
                <w:i/>
              </xsl:when>
              <xsl:when  test="@role = ( 'Italicstrong' , 'BoldItalic' )">
                <w:b/>
                <w:i/>
              </xsl:when>
              <xsl:when  test="@role = ( 'SmallCaps' )">
                <w:smallCaps  w:val="true"/>
              </xsl:when>
              <xsl:when  test="@role = ( 'SmallCapsstrong' )">
                <w:smallCaps  w:val="true"/>
                <w:b/>
              </xsl:when>
              <xsl:when  test="@role = ( 'ItalicSmallCaps' )">
                <w:smallCaps  w:val="true"/>
                <w:i/>
              </xsl:when>
              <xsl:when  test="@role = ( 'br' )" />
              <xsl:when  test="not(@role)">
                <xsl:message  select="concat( 'Warning: missing role attribute for element ', name(), ' - falling back to &quot;italic&quot;')"/>
                <w:i/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message  select="concat( 'Warning: unexpected role attribute value &quot;', @role, '&quot; for element ', name(), ' - falling back to &quot;italic&quot;')"/>
                <w:i/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:with-param>
    </xsl:apply-templates>
  </xsl:template>
  

  <xsl:template  match="subscript | superscript"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:apply-templates  select="node()"  mode="#current" >
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

  <xsl:template  match="dbk:tabs"  mode="hub:default" />
  <xsl:template  match="dbk:tab"  mode="hub:default">
    <w:r>
      <w:tab/>
    </w:r>
  </xsl:template>

</xsl:stylesheet>

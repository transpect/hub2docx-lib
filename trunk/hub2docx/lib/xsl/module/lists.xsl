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

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink o w m wp r"
>


  <xsl:variable name="hub:list-element-names" as="xs:string+" select="( 'itemizedlist' , 'orderedlist', 'bibliography', 'bibliodiv', 'variablelist' )"/>

<!-- ================================================================================ -->
<!-- helper functions -->
<!-- ================================================================================ -->


  <!-- This list is used in order to speed up the index-of(), which would be extremly time consuming if operating on the sequence of lists itself. -->
  <xsl:variable  name="generatedIdOfAllLists">
    <xsl:for-each  select="//*[ local-name() = $hub:list-element-names]">
      <!-- the letex:-namespace is used here for clarity, because we use 'xpath-default-namespace = "http://docbook.org/ns/docbook"' and the result of that would not be expected -->
      <letex:list>
        <letex:id><xsl:value-of select="generate-id()"/></letex:id>
        <letex:pos><xsl:value-of select="position()"/></letex:pos>
      </letex:list>
    </xsl:for-each>
  </xsl:variable>


  <!-- The value numId/@val identifies a list unambiguously.
       This function returns an unambiguous numId/@val for the list-node given as argument, which is not already in use in the template numbering.xml document. -->
  <xsl:function  name="letex:getNumId">
    <xsl:param  name="generatedIdOfList"  as="xs:string"/>
    <xsl:choose>
      <xsl:when  test="$generatedIdOfAllLists//letex:list[ ./letex:id eq $generatedIdOfList ]">
        <xsl:value-of  select="1001 + $generatedIdOfAllLists//letex:list[ ./letex:id eq $generatedIdOfList ]/letex:pos - 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message  terminate="no"   select="$generatedIdOfAllLists"/>
        <xsl:message  terminate="no"   select="$generatedIdOfList"/>
        <xsl:message  terminate="yes"  select="'ERROR: letex:getNumId() could not find a list-id in the global variable $generatedIdOfAllLists'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function  name="letex:getAbstractNumId" as="xs:integer">
    <xsl:param  name="list"  as="node()"/>
    <!-- §§§ This assignment is source data specific and has to be adapted according to the list types occuring.
             Please note that is very easy to adapt the style-information related to this abstractNumIds by running Microbugs Office 2007 Word. -->
    <!-- § I use values starting from 10 here, because the current template contains <w:multiLevelType w:val="hybridMultilevel"/>-lists there. -->
    <xsl:value-of  select="if      ( $list[ self::itemizedlist[ not( @mark) ] ] )			then 14 
                           else if ( $list[ self::itemizedlist[ @mark eq 'nomark' ] ] )			then 11
                           else if ( $list[ self::itemizedlist[ @mark eq 'note' ] ] )			then 12
                           else if ( $list[ self::itemizedlist[ @mark eq 'thumb' ] ] )			then 36
                           else if ( $list[ self::orderedlist [ not( @mark) ] ] )			then 13 
                           else if ( $list[ self::orderedlist [ @numeration eq 'loweralpha' ] ] )	then 15
                           else if ( $list[ self::bibliography[ every $bi in .//bibliomisc satisfies $bi/@role = 'numberedRef' ] ] )			then 0
                           else if ( $list[ self::bibliodiv[ every $bi in .//bibliomisc satisfies $bi/@role = 'numberedRef' ] ] )			then 0
                           else if ( $list[ self::bibliography ] )			then 38
                           else if ( $list[ self::bibliodiv ] )			then 38
                           else error( (), concat(   'ERROR: list type could not be determined. Please enlighten letex:getAbstractNumId() how to guess it.&#x0A;'
                                                   , 'list element name: ', $list/local-name(), '&#x0A;'
                                                   , for $attr in $list/@* return concat( 'attribut @', $attr/local-name(), ' = ', $attr, '', '&#x0A;')
                                                 ))
                          "/>
  </xsl:function>


<!-- ================================================================================ -->
<!-- TEMPLATES -->
<!-- ================================================================================ -->

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


  <!-- Dissolve paras with lists into separate block-level elements -->
  <xsl:template  match="para[ *[ local-name() = $hub:list-element-names] ]"  mode="hub:default_" priority="10">
    <xsl:variable name="dissolve" as="element(*)+">
      <xsl:for-each-group select="node()" group-adjacent="exists(self::*[ local-name() = $hub:list-element-names])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:sequence select="current-group()" />
          </xsl:when>
          <xsl:otherwise>
            <para xmlns="http://docbook.org/ns/docbook">
              <xsl:sequence select="@*" />
              <xsl:sequence select="current-group() except *[ local-name() = $hub:list-element-names]" />
            </para>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:apply-templates select="$dissolve" mode="#current" />
  </xsl:template>

  <xsl:template  match="para[ *[ local-name() = $hub:list-element-names] ]"  mode="hub:default hub:default_renderFootnote" priority="10">
    <xsl:param name="fn" as="element(footnote)?" tunnel="yes"/>
    <xsl:variable name="dissolve" as="element(*)+">
      <xsl:for-each-group select="node()" group-adjacent="exists(self::*[ local-name() = $hub:list-element-names])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:sequence select="current-group()" />
          </xsl:when>
          <xsl:otherwise>
            <para xmlns="http://docbook.org/ns/docbook">
              <xsl:sequence select="@*" />
              <xsl:sequence select="current-group() except *[ local-name() = $hub:list-element-names]" />
            </para>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:apply-templates select="$dissolve" mode="#current" />
  </xsl:template>


  <xsl:template  match="*[ local-name() = $hub:list-element-names]"  mode="hub:default hub:default_renderFootnote">
    <xsl:apply-templates  mode="hub:default"/>
  </xsl:template>


  <xsl:template  match="*[ local-name() = $hub:list-element-names]/listitem"  mode="hub:default hub:default_renderFootnote">
    <xsl:apply-templates  mode="hub:default"/>
  </xsl:template>

  <xsl:template  match="variablelist | varlistentry | varlistentry/listitem"  mode="hub:default">
    <xsl:apply-templates  mode="hub:default"/>
  </xsl:template>

  <xsl:template  match="varlistentry/term | varlistentry/listitem/para | varlistentry/listitem/simpara"  mode="hub:default hub:default_renderFootnote" priority="2">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{if (self::term) then 'deflistterm' else 'deflistdef'}"/>
      </w:pPr>
      <xsl:variable name="rPrContent" as="element(*)*">
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes" as="element(*)*"/>
      </xsl:apply-templates>
      <xsl:if test="../@xml:id">
        <w:bookmarkEnd    w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
  </xsl:template>


  <!-- a para within listitem creates a w:p with special pPr-properties -->
  <xsl:template  match="*[ local-name() = $hub:list-element-names]/listitem/para"  mode="hub:default hub:default_renderFootnote">
    <xsl:variable name="ilvl"  select="count( ancestor::*[self::*[ local-name() = $hub:list-element-names]]) - 1" as="xs:integer"/>
    <xsl:variable name="numId" select="letex:getNumId( ancestor::*[self::*[ local-name() = $hub:list-element-names]][1]/generate-id() )" />
    <!-- §§ should we consider scoping? -->
    <xsl:variable name="in-blockquote" select="if (ancestor::blockquote) then 'Bq' else ''" as="xs:string" />
    <xsl:variable name="continuation" select="if (position() eq 1) then '' else 'Cont'" as="xs:string" />
    <w:p>
      <w:pPr>
        <!-- §§ ListParagraph okay? -->
        <w:pStyle w:val="ListParagraph{$in-blockquote}{$continuation}"/>
        <xsl:if test="$continuation eq ''">
          <w:numPr>
            <w:ilvl w:val="{$ilvl}"/>
            <w:numId w:val="{$numId}"/>
          </w:numPr>
        </xsl:if>
        <!-- §§ okay? -->
<!--         <w:ind w:left="{180 + ( 180 * $ilvl )}"/> -->
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="hub:default"/>
    </w:p>
  </xsl:template>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="numbering" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="variablelist"  mode="numbering" priority="2"/>

  <xsl:template  match="*[ local-name() = $hub:list-element-names]"  mode="numbering">

    <xsl:variable name="ilvl"  select="count( ancestor-or-self::*[self::*[ local-name() = $hub:list-element-names]]) - 1" as="xs:integer"/>
    <!-- ~~~~~~~~~~~~~~~~~~~~ w:num ~~~~~~~~~~~~~~~~~~~~ -->
    <w:num>
      <xsl:attribute  name="w:numId"  select="letex:getNumId( generate-id())"/>
      <w:abstractNumId w:val="{letex:getAbstractNumId( .)}"/>
      <w:lvlOverride w:ilvl="{if(starts-with(local-name(), 'biblio')) then 0 else $ilvl}">
        <w:startOverride w:val="1" />
      </w:lvlOverride> 
    </w:num>
    <xsl:apply-templates  mode="#current"/>

    <!-- ~~~~~~~~~~~~~~~~~~~~ w:abstractNumId ~~~~~~~~~~~~~~~~~~~~ -->
    <!-- Currently we do not want to generate the w:abstractNum-elements referenced by the w:num/w:numId/@val.
         Instead we reference the existing w:abstractNum from the template-numbering.xml-file and adapt the visual appearance using Microbugs Office Word 2007.
         -->
<!--     <w:abstractNum> -->
<!--       <xsl:attribute  name="w:abstractNumId"  select="letex:getAbstractNumId( .)"/> -->
<!--       <\!-\- because we apply a separate w:num/w:abstractNum to each *[ local-name() = $hub:list-element-names] regardless of numbering level, we do need only one <w:lvl> with @w:ilvl="0" -\-> -->
<!--       <w:lvl w:ilvl="0"> -->
<!--         <w:start w:val="1"/> -->
<!--         <w:numFmt w:val="{if ( @numeration eq 'loweralpha') -->
<!--                           then 'lowerLetter' -->
<!--                           else 'decimal'}"/> -->
<!--         <\!-\- §§§ check against source document rendering! -\-> -->
<!--         <w:lvlText w:val="%1)"/> -->
<!--         <w:lvlJc w:val="left"/> -->
<!--       </w:lvl> -->
<!--     </w:abstractNum> -->

  </xsl:template>


  <xsl:template  match="node()"  mode="numbering"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>


</xsl:stylesheet>

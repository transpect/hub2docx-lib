<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xpath-default-namespace = "http://docbook.org/ns/docbook"
    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn css xlink o w m wp r vt hub">

  <!-- ================================================================================ -->
  <!-- VARIABLES -->
  <!-- ================================================================================ -->

  <xsl:param name="render-index-list" select="'no'" as="xs:string"/>

  <xsl:key name="by-genid" match="*" use="generate-id()"/>

  <xsl:variable name="page-settings" as="element(w:sectPr)">
    <xsl:variable name="a4-portrait-width" select="11906" as="xs:integer" />
    <xsl:variable name="a4-portrait-height" select="16838" as="xs:integer" />
    <xsl:variable name="sqrt2" select="1.41421356" as="xs:double" />
    <xsl:variable name="height" select="if ($a3paper eq 'yes') then xs:integer($sqrt2 * $a4-portrait-height) else $a4-portrait-height" as="xs:integer" />
    <xsl:variable name="width" select="if ($a3paper eq 'yes') then xs:integer($sqrt2 * $a4-portrait-width) else $a4-portrait-width" as="xs:integer" />
    <w:sectPr>
      <w:pgSz w:w="{if ($landscape eq 'yes') then $height else $width}" w:h="{if ($landscape eq 'yes') then $width else $height}"
        w:orient="{if ($landscape eq 'yes') then 'landscape' else 'portrait'}"/>
      <w:pgMar w:top="960" w:right="960" w:bottom="960" w:left="800" w:header="709" w:footer="709" w:gutter="0"/>
      <w:cols w:space="708"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </xsl:variable>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="*[@role eq 'web']"  mode="hub:default" priority="2000">
    <xsl:message>Ignoring role=web content: 
    <xsl:sequence select="." />
    </xsl:message>
  </xsl:template>

  <xsl:template  match="*[@role eq 'print']"  mode="hub:default" priority="2000">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="info[parent::book]"  mode="hub:default" priority="3"/>

  <!-- need this for subsequent key() operations (they are in disguise sometimes!) -->
  <xsl:variable name="root" select="/" />
<!--  <xsl:variable name="root" select="/" as="document-node(element(*))" />-->

  <xsl:template  match="/*[not(self::para)]"  mode="hub:default">
    <xsl:message select="'hub2docx root element:', name()"/>
    <!-- speed up the index-of() a little bit -->
    <xsl:variable  name="rels" select="for $f 
      in (  //*[local-name() = ('mediaobject', 'inlinemediaobject')] 
      (: | //link[@role eq 'uri' or (not(@role) and @xlink:href)] :)
      ) 
      return generate-id($f)" as="xs:string*"/>
    <w:root_converted>
      <w:containerProps>
        <xsl:apply-templates select="info/keywordset[@role = 'custom-meta']" mode="#current"/>
      </w:containerProps>
      <w:styles />
      <w:numbering>
        <xsl:apply-templates mode="numbering"/>
      </w:numbering>
      <w:footnotes>
        <xsl:apply-templates select="//footnote" mode="footnotes"/>
      </w:footnotes>
      <w:endnotes />
      <w:settings >
        <xsl:apply-templates select="info/keywordset[@role = 'docVars']" mode="#current"/>
      </w:settings>
      <w:comments>
        <xsl:apply-templates select="//annotation" mode="comments"/>
      </w:comments>
      <w:fonts />
      <w:docRels>
        <rel:Relationships>
          <xsl:apply-templates select="key('by-genid', $rels, $root)" mode="documentRels">
            <xsl:with-param name="rels" select="$rels" as="xs:string*" tunnel="yes"/>
          </xsl:apply-templates>
        </rel:Relationships>
      </w:docRels>
      <w:header>
        <xsl:for-each select="//*[not(parent::css:page)][@css:page][tr:is-header(.)]">
          <xsl:apply-templates select="." mode="header"/>
        </xsl:for-each>
      </w:header>
      <w:footer>
        <xsl:for-each select="//*[not(parent::css:page)][@css:page][tr:is-footer(.)]">
          <xsl:apply-templates select="." mode="footer"/>
        </xsl:for-each>
      </w:footer>
      <w:document>
        <w:body>
          <xsl:next-match>
            <xsl:with-param name="rels" select="$rels" as="xs:string*" tunnel="yes"/>
          </xsl:next-match>
          <xsl:if test="$render-index-list eq 'yes' and exists(//indexterm)">
            <xsl:call-template name="create-index-list">
              <xsl:with-param name="indexterms" select="//indexterm" as="element(indexterm)*"/>
              <xsl:with-param name="lang" select="(/*/@xml:lang, 'de')[1]" as="xs:string"/>
            </xsl:call-template>
          </xsl:if>
        </w:body>
      </w:document>
    </w:root_converted>
    <!-- see idEmphasisWithoutRoleAttribute in text-runs.xsl -->
    <xsl:if test="//emphasis[not(@role)]">
      <xsl:message 
        select="'Info: There are one or more emphasis elements without a role attribute - falling back to &quot;italic&quot;'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template  match="book | Body | hub"  mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template match="keywordset[@role = 'custom-meta']" mode="hub:default">
    <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"> 
      <xsl:apply-templates mode="#current"/>
    </Properties>
  </xsl:template>

  <xsl:template match="keywordset[@role = 'custom-meta']/keyword" mode="hub:default">
    <property xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"
      fmtid="{{D5CDD505-2E9C-101B-9397-08002B2CF9AE}}" pid="fill-me-with-an-int" name="{@role}"> 
      <vt:lpwstr>
        <xsl:value-of select="."/>
      </vt:lpwstr>
    </property>
  </xsl:template>
  
  <xsl:template match="keywordset[@role = 'docVars']" mode="hub:default">
    <w:docVars>
      <xsl:apply-templates mode="#current"/>
    </w:docVars>
  </xsl:template>

  <xsl:template match="keywordset[@role = 'docVars']/keyword" mode="hub:default">
    <w:docVar w:name="{@role}" w:val="{.}"/>
  </xsl:template>
  
  <xsl:template  match="chapter"  mode="hub:default">
    <xsl:message select="'...Chapter: ', string-join((title, info/title, para[1])[1]//text()[not(ancestor::indexterm)], '')"/>
    <xsl:apply-templates select="node()[not(. instance of text())]"  mode="#current" />
  </xsl:template>

  <xsl:variable name="structure-elements" as="xs:string*"
    select="('acknowledgements', 'appendix', 'bibliodiv', 'bibliography', 'blockquote', 'dedication', 'book', 'bookinfo', 
    'caution', 'chapter', 'colophon', 'epigraph', 'example', 'formalpara', 'glossary', 'glossdiv', 'note', 'part', 
    'partintro', 'preface', 'section', 'sect1', 'sect2', 'sect3', 'sect4', 
    'sect5', 'sect6', 'sidebar', 'simplesect', 'tip', 'warning', 'div', 'index', 'preface')"/>

  <xsl:template  match="*[name() = $structure-elements]"  mode="hub:default" priority="-1">
    <xsl:apply-templates  select="node()[not(. instance of text())]"  mode="#current" />
  </xsl:template>
  
  <xsl:template  match="titleabbrev"  mode="hub:default" />

  <xsl:template  match="toc"  mode="hub:default" />
  
  <!-- render attribution after blockquote content-->
  <xsl:template  match="*[local-name() = ('blockquote', 'epigraph')][attribution]"  mode="hub:default">
    <xsl:apply-templates  select="* except attribution, attribution"  mode="#current" />
  </xsl:template>

  <xsl:function name="tr:headinglevel" as="xs:integer">
    <xsl:param name="context" as="element(*)?" />
    <xsl:variable  name="origLevel" select="replace( $context/../@role, '(^| )(head|berschrift)([0-9]*).*$', '$2')" as="xs:string?"/>
    <xsl:value-of select="if ( $origLevel castable as xs:integer) then number($origLevel) + 1 
                          else count( $context/(ancestor::part | ancestor::chapter | ancestor::glossdiv | ancestor::*[starts-with(local-name(), 'sect')]) ) + 1"/>
  </xsl:function>
  
  <xsl:template  match="info"  mode="hub:default">
    <xsl:apply-templates  select="node()[not(. instance of text())]"  mode="#current" />
  </xsl:template>
  
  <xsl:template match="*[local-name() = $structure-elements]/title
      | *[local-name() = $structure-elements]/info/title
      | book/subtitle
      | book/info/subtitle
      | part/subtitle
      | chapter/subtitle
      | section/subtitle
      | book/info/subtitle
      | bridgehead"
    mode="hub:style-name">
    <w:pStyle>
      <xsl:attribute name="w:val">
        <xsl:choose>
          <!-- book/title, book/subtitle -->
          <xsl:when test="parent::book or parent::info[parent::book]">
            <xsl:value-of select="concat(
                                    upper-case(
                                      substring(name(.),1,1)
                                    ),
                                    substring(name(.),2)
                                  )"/>
          </xsl:when>
          <!-- part/title, part/subtitle -->
          <xsl:when test="parent::part or parent::info[parent::part]">
            <xsl:value-of select="concat(
                                    'Part',
                                    upper-case(
                                      substring(name(.),1,1)
                                    ),
                                    substring(name(.),2)
                                  )"/>
          </xsl:when>
          <xsl:when test="parent::*[local-name() = ('bibliography')]">
            <xsl:value-of select="concat($heading-prefix, tr:headinglevel(ancestor::*[self::section or self::chapter][1]/title) + 1)"/>
          </xsl:when>
          <xsl:when test="parent::*[local-name() = ('bibliodiv')]">
            <xsl:value-of select="concat($heading-prefix, tr:headinglevel(ancestor::*[self::section or self::chapter][1]/title) + 2)"/>
          </xsl:when>
          <xsl:when test="parent::*[
                            starts-with(local-name(), 'sect') or 
                            self::info and parent::*[local-name() = ('appendix', 'chapter', 'glossary', 'glossdiv', 'preface', 'simplesect', 'index')] or 
                            local-name() = ('appendix', 'chapter', 'glossary', 'glossdiv', 'preface', 'simplesect', 'index')
                          ]">
            <xsl:value-of select="concat( $heading-prefix, string(tr:headinglevel(.)))"/>
          </xsl:when>
          <xsl:when test="parent::*[local-name() = 'acknowledgements']">
            <xsl:value-of select="concat( $heading-prefix, string(tr:headinglevel(.)))"/>
           </xsl:when>
          <!-- 'blockquote', 'example', 'formalpara', etc. -->
          <xsl:otherwise>
            <xsl:value-of select="if (parent::info) then concat(local-name(../parent::*), 'title') else concat(local-name(parent::*), 'title')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
    </w:pStyle>
  </xsl:template>
  
  <xsl:template
    match="
      *[local-name() = $structure-elements]/title
      | *[local-name() = $structure-elements]/info/title
      | book/subtitle
      | book/info/subtitle
      | chapter/subtitle
      | section/subtitle
      | book/info/subtitle
      | bridgehead"
    mode="hub:default" priority="3">
    <w:p origin="default_docstruct_title">
      <xsl:call-template name="hub:pPr"/>
      <xsl:variable name="rPrContent" as="element(*)*">
        <xsl:apply-templates select="@css:color, @css:font-size" mode="props"/>
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart w:id="{generate-id(..)}" w:name="bm_{generate-id(..)}_"/>
      </xsl:if>

      <xsl:apply-templates mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes" as="element(*)*"/>
      </xsl:apply-templates>

      <xsl:if test="../@xml:id">
        <w:bookmarkEnd w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
  </xsl:template>
  
  <xsl:template match="w:bookmarkStart/@w:id | w:bookmarkEnd/@w:id" mode="hub:clean">
    <xsl:param name="bookmark-ids" as="xs:string+" tunnel="yes"/>
    <xsl:attribute name="{name()}" select="index-of($bookmark-ids, .)"/>
  </xsl:template>

  <xsl:template  match="/w:root_converted//w:root_converted"  mode="hub:clean">
    <xsl:apply-templates select="w:document/w:body/node()" mode="#current"/>
  </xsl:template>

  <xsl:template  match="title"  mode="hub:default"  priority="-1">
    <xsl:message  terminate="no" select="concat( 'ERROR: title parent not expected: ', parent::*/name())"/>
  </xsl:template>

</xsl:stylesheet>

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

  <xsl:variable  name="table-scale"  select="20.0"  as="xs:double" />

  <xsl:template  match="table | informaltable"  mode="hub:default">
    <xsl:apply-templates  select="self::informaltable/@xml:id | caption | info"  mode="#current" />
    <xsl:choose>
      <xsl:when test="tgroup">
        <xsl:for-each select="tgroup">
          <xsl:call-template name="create-table"/>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="create-table"/>
      </xsl:otherwise>
    </xsl:choose>
    <w:p/>
  </xsl:template>

  <xsl:template  match="informaltable/@xml:id"  mode="hub:default">
    <w:p>
      <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      <w:r>
        <w:t>&#xa0;</w:t>
      </w:r>
      <w:bookmarkEnd    w:id="{generate-id(..)}"/>
    </w:p>
  </xsl:template>
  
  <xsl:template name="create-table" as="node()+">
    <xsl:param name="tblPrContent" as="element(*)*" tunnel="yes" />
    <w:tbl>
      <xsl:variable name="current-color" select="replace( letex:current-color(., (), ()), '#', '' )" />
      <xsl:variable name="default-tblPrContent" as="element(*)+">
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblBorders>
          <xsl:for-each select="('top', 'left', 'bottom', 'right' )">
            <xsl:element name="w:{replace(., 'Border', '')}">
              <xsl:attribute name="w:val"    select="'single'" />
              <xsl:attribute name="w:sz"     select="10" />
              <xsl:attribute name="w:space " select="0" />
              <xsl:attribute name="w:color " select="$current-color" />
            </xsl:element>
          </xsl:for-each>
        </w:tblBorders>
        <w:tblLook w:val="0000"/>
      </xsl:variable>
      <w:tblPr>
        <xsl:sequence select="letex:merge-props($tblPrContent, $default-tblPrContent)" />
      </w:tblPr>
      <w:tblGrid>
        <xsl:apply-templates select="colspec | colgroup | col | colgroup/col" mode="#current"/>
      </w:tblGrid>
      <xsl:variable name="name-to-int-map" as="document-node(element(map))">
        <xsl:document>
          <map xmlns="http://docbook.org/ns/docbook">
            <xsl:for-each select="colspec">
              <item key="{@colname}" val="{@colnum}"/>
            </xsl:for-each>
          </map>
        </xsl:document>
      </xsl:variable>
      <xsl:apply-templates select="(thead, tbody, tfoot)" mode="#current">
        <xsl:with-param name="name-to-int-map" select="$name-to-int-map" tunnel="yes"/>
      </xsl:apply-templates>
      <!-- the remainder should be tr or row elements: -->
      <xsl:apply-templates select="* except (caption | info | colspec | colgroup | col | thead | tbody | tfoot)" mode="#current">
        <xsl:with-param name="name-to-int-map" select="$name-to-int-map" tunnel="yes"/>
      </xsl:apply-templates>
    </w:tbl>
    <xsl:apply-templates  select=".//footnote"  mode="hub:default_renderFootnote">
      <xsl:sort select="@label"/>
      <xsl:sort select="generate-id(.)"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="colgroup" mode="hub:default" />

  <xsl:template  match="col | colspec"  mode="hub:default">
    <w:gridCol>
      <xsl:if test="@width | @colwidth">
        <xsl:attribute  name="w:w"  
          select="xs:integer(
                    xs:double(
                      replace(
                        (@width, @colwidth)[1], 
                        '(mm|pt)$',
                        ''
                      )
                    ) * $table-scale
                  )" />
      </xsl:if>
    </w:gridCol>
  </xsl:template>

  <xsl:template  match="thead | tbody | tfoot"  mode="hub:default">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

  <xsl:template  match="tr | row"  mode="hub:default">
    <w:tr>
      <xsl:variable  name="trPr">
        <xsl:apply-templates  select="@class"  mode="trPr" />
        <xsl:if test="ancestor::thead">
          <w:tblHeader/>
        </xsl:if>
      </xsl:variable>
      <xsl:if test="$trPr">
        <w:trPr>
          <xsl:sequence  select="$trPr" />
        </w:trPr>
      </xsl:if>
      <xsl:apply-templates  mode="#current"/>
    </w:tr>
  </xsl:template>

  <xsl:key name="map" match="map/item" use="@key" />

  <xsl:function name="letex:cals-colspan" as="attribute(colspan)?">
    <xsl:param name="map" as="document-node(element(map))" />
    <xsl:param name="namest" as="xs:string?" />
    <xsl:param name="nameend" as="xs:string?" />
    <xsl:if test="$namest and $nameend">
      <xsl:attribute name="colspan" select="xs:integer(key('map', $nameend, $map)/@val) - xs:integer(key('map', $namest, $map)/@val) + 1" />
    </xsl:if>
  </xsl:function>

  <xsl:template  match="th | td | entry"  mode="hub:default">
    <xsl:param name="name-to-int-map" as="document-node(element(map))" tunnel="yes"/>
    <w:tc>
      <xsl:variable  name="tcPr">
        <xsl:apply-templates  select="(@colspan, letex:cals-colspan($name-to-int-map, @namest, @nameend))[1], @class"  mode="tcPr" />
        <xsl:if test="self::th or ../../self::thead">
          <w:shd w:val="clear" w:color="auto" 
            w:fill="{replace( letex:current-color(., 'grey', if(../../self::thead) then 'medium' else 'light'), '#', '' )}"/>
        </xsl:if>
      </xsl:variable>
      <xsl:if test="$tcPr">
        <w:tcPr>
          <xsl:sequence  select="$tcPr" />
        </w:tcPr>
      </xsl:if>
			<xsl:choose>
				<xsl:when test="not( * | text()[normalize-space(.)] )">
					<!-- [ISO/IEC 29500-1 1st Edition] - 17.4.66 tc (Table Cell): 
							"If a table cell does not include at least one block-level element, 
							 then this document shall be considered corrupt." -->
					<w:p/>
				</xsl:when>
				<xsl:when test="text()[normalize-space(.)]">
					<w:p>
            <xsl:apply-templates mode="#current"/>
          </w:p>
        </xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="*" mode="#current"/>
				</xsl:otherwise>
			</xsl:choose>
    </w:tc>
  </xsl:template>

  <xsl:template match="@colspan" mode="tcPr">
    <w:gridSpan w:val="{.}" />
  </xsl:template>

  <xsl:template  match="@class"  mode="tcPr">
    <xsl:choose>
      <xsl:when test="matches(., 'Border')">
        <w:tcBorders>
          <xsl:variable name="context" select="." as="attribute(class)"/>
          <xsl:for-each select="(tokenize(., '\s+'))[matches(., 'Border$')]">
            <xsl:element name="w:{replace(., 'Border', '')}">
              <xsl:attribute name="w:val"    select="'single'" />
              <xsl:attribute name="w:sz"     select="10" />
              <xsl:attribute name="w:space " select="0" />
              <xsl:attribute name="w:color " select="replace( letex:current-color($context, '', 'dark'), '#', '' )" />
            </xsl:element>
          </xsl:for-each>
        </w:tcBorders>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template  match="@*"  mode="trPr tcPr"  priority="-4" />


  <xsl:template  match="caption[ parent::*/local-name() = ( 'table' , 'informaltable') ]"  mode="hub:default">
      <xsl:apply-templates  mode="#current"/>
  </xsl:template>


  <!-- Assign an appropriate pStyle to the Caption-Paras.
       §§ ATTENTION: this should be solved otherwise, i.e. a generic w:p-generator-template should inherit the pStyle-content. See implementation of text()-Nodes to w:r .
       -->
  <xsl:template  match="caption/para"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle  w:val="Caption"/>
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="#current"/>
    </w:p>
  </xsl:template>


  <xsl:template  match="info[ parent::*/local-name() = ( 'table' , 'informaltable') ]"  mode="hub:default">
    <xsl:message  select="'ERROR: element table/info not yet implemented!'"/>
  </xsl:template>


  <xsl:template  match="union[ parent::*/local-name() = ( 'table' , 'informaltable') ]"  mode="hub:default">
    <xsl:message  select="'ERROR: element table/union not yet implemented!'"/>
  </xsl:template>


</xsl:stylesheet>

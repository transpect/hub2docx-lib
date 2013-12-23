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
    xmlns:css = "http://www.w3.org/1996/css"
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
    <xsl:variable name="tblPrContent" as="element(*)*">
      <xsl:apply-templates select="@frame, @css:text-align, @css:width" mode="tblPr"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="tgroup">
        <xsl:for-each select="tgroup">
          <xsl:call-template name="create-table">
            <xsl:with-param name="tblPrContent" select="$tblPrContent" tunnel="yes"/>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="create-table">
          <xsl:with-param name="tblPrContent" select="$tblPrContent" tunnel="yes"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
    <w:p>
      <xsl:variable name="pPr">
        <xsl:apply-templates  select="@css:page-break-after" mode="props" />
      </xsl:variable>
      <xsl:if  test="$pPr">
        <w:pPr>
          <xsl:sequence  select="$pPr" />
        </w:pPr>
      </xsl:if>
    </w:p>
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
            <xsl:element name="w:{current()}">
              <xsl:attribute name="w:val"    select="'single'" />
              <xsl:attribute name="w:sz"     select="10" />
              <xsl:attribute name="w:space " select="0" />
              <xsl:attribute name="w:color " select="if($current-color ne '') then $current-color else '000000'" />
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

  <!--<xsl:template  match="thead | tbody | tfoot"  mode="hub:default_DISABLED">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>-->
  
  <xsl:template match="thead | tbody | tfoot" mode="hub:default">
    <xsl:param name="name-to-int-map" as="document-node(element(map))" tunnel="yes"/>
    <xsl:variable name="cols" select="parent::*/@cols"/>
    <xsl:for-each-group select="node()" group-starting-with="*[self::row or self::tr][sum(for $i in (*[self::entry or self::td or self::th]) return if (exists((@colspan, letex:cals-colspan($name-to-int-map, @namest, @nameend))[1])) then (@colspan, letex:cals-colspan($name-to-int-map, @namest, @nameend))[1] else 1)=$cols]">
      <xsl:sequence select="letex:position-trs((),current-group(),$name-to-int-map)"/>
    </xsl:for-each-group>
  </xsl:template>
  
  <xsl:function name="letex:position-trs" as="element(w:tr)*">
    <xsl:param name="built-rows" as="element(w:tr)*"/>
    <xsl:param name="cals-rows" as="element(*)*"/>
    <xsl:param name="name-to-int-map" as="document-node(element(map))"/>
    
    <xsl:choose>
      <xsl:when test="empty($cals-rows)">
        <xsl:sequence select="$built-rows"/>
      </xsl:when>
      <xsl:when test="empty($built-rows)">
        <xsl:variable name="new-built-rows" as="element(w:tr)*">
          <w:tr>
            <xsl:variable  name="trPr">
              <xsl:apply-templates  select="$cals-rows[1]/@class | $cals-rows[1]/@css:height | $cals-rows[1]/@css:page-break-inside"  mode="trPr" />
              <xsl:if test="$cals-rows[1]/ancestor::thead">
                <w:tblHeader/>
              </xsl:if>
            </xsl:variable>
            <xsl:if test="$trPr">
              <w:trPr>
                <xsl:sequence  select="$trPr" />
              </w:trPr>
            </xsl:if>
            <xsl:for-each select="$cals-rows[1]/*[self::entry or self::td or self::th]">
              <xsl:variable  name="tcPr">
                <xsl:apply-templates  select="(@colspan, letex:cals-colspan($name-to-int-map, @namest, @nameend))[1], @class, (@rowsep, @colsep)[1], @css:*"  mode="tcPr" />
                <xsl:if test="self::th or ../../self::thead">
                  <w:shd w:val="clear" w:color="auto" 
                    w:fill="{replace( letex:current-color(., 'grey', if(../../self::thead) then 'medium' else 'light'), '#', '' )}"/>
                </xsl:if>
                <xsl:apply-templates select="@css:background-color" mode="tcPr"/>
              </xsl:variable>
              <xsl:variable name="pPr">
                <xsl:apply-templates select="para/@css:page-break-after" mode="props"/>
              </xsl:variable>
              <xsl:variable name="morerows" as="xs:string" select="if (exists(@morerows)) then @morerows else if (exists(@rowspan)) then string(number(@rowspan)-1) else ''"/>
              <w:tc>
                <w:tcPr>
                  <xsl:if test="not($morerows='')">
                    <w:vMerge w:val="restart" hub:morerows="{$morerows}"/>
                  </xsl:if>
                  <xsl:if test="exists(@namest) or exists(@colspan)">
                    <w:hMerge w:val="restart"/>
                  </xsl:if>
                  <xsl:if test="$tcPr">
                    <xsl:sequence  select="$tcPr" />
                  </xsl:if>
                </w:tcPr>
                <xsl:apply-templates mode="hub:default"/>
              </w:tc>
              <xsl:if test="exists(@namest) or exists(@colspan)">
                <xsl:for-each select="1 to (xs:integer(@colspan), xs:integer(letex:cals-colspan($name-to-int-map, @namest, @nameend)))[1]-1">
                  <w:tc>
                    <w:tcPr>
                      <xsl:if test="not($morerows='')">
                        <w:vMerge w:val="restart" hub:morerows="{$morerows}"/>
                      </xsl:if>
                      <w:hMerge w:val="continue"/>
                      <xsl:if test="$tcPr">
                        <xsl:sequence  select="$tcPr" />
                      </xsl:if>
                      <w:p>
                        <xsl:if test="$pPr">
                          <w:pPr>
                            <xsl:sequence  select="$pPr" />
                          </w:pPr>
                        </xsl:if>
                      </w:p>
                    </w:tcPr>
                  </w:tc>
                </xsl:for-each>
              </xsl:if>
            </xsl:for-each>
          </w:tr>
        </xsl:variable>
        <xsl:sequence select="letex:position-trs($new-built-rows,$cals-rows[position() gt 1],$name-to-int-map)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="new-built-rows" as="element(w:tr)*">
          <xsl:sequence select="$built-rows"/>
          <w:tr>
            <xsl:variable  name="trPr">
              <xsl:apply-templates  select="$cals-rows[1]/@class | $cals-rows[1]/@css:height | $cals-rows[1]/@css:page-break-inside"  mode="trPr" />
              <xsl:if test="$cals-rows[1]/ancestor::thead">
                <w:tblHeader/>
              </xsl:if>
            </xsl:variable>
            <xsl:if test="$trPr">
              <w:trPr>
                <xsl:sequence  select="$trPr" />
              </w:trPr>
            </xsl:if>
            <xsl:sequence select="letex:position-tcs($built-rows[last()]/w:tc,$cals-rows[1]/*[self::entry or self::td or self::th],$name-to-int-map)"/>
          </w:tr>
        </xsl:variable>
        <xsl:sequence select="letex:position-trs($new-built-rows,$cals-rows[position() gt 1],$name-to-int-map)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="letex:position-tcs" as="element(w:tc)*">
    <xsl:param name="built-entries" as="element(w:tc)*"/>
    <xsl:param name="cals-entries" as="element(*)*"/>
    <xsl:param name="name-to-int-map" as="document-node(element(map))"/>

    <xsl:choose>
      <xsl:when test="empty($cals-entries)">
        <xsl:for-each select="$built-entries">
          <w:tc>
            <w:tcPr>
              <w:vMerge w:val="continue" hub:morerows="{number(descendant::w:vMerge[letex:same-scope(., current())]/@hub:morerows)-1}"/>
              <xsl:sequence select="w:tcPr/node()[not(self::w:vMerge)]"/>
            </w:tcPr>
            <w:p>
              <xsl:sequence select="w:p/w:pPr"/>
            </w:p>
          </w:tc>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$built-entries[1][descendant::w:vMerge[@hub:morerows and number(@hub:morerows) gt 0]]">
        <w:tc>
          <w:tcPr>
            <w:vMerge w:val="continue" hub:morerows="{number($built-entries[1]/descendant::w:vMerge/@hub:morerows)-1}"/>
            <xsl:sequence select="$built-entries[1]/w:tcPr/node()[not(self::w:vMerge)]"/>
          </w:tcPr>
          <w:p>
            <xsl:sequence select="$built-entries[1]/w:p/w:pPr"/>
          </w:p>
        </w:tc>
        <xsl:sequence select="letex:position-tcs($built-entries[position() gt 1],$cals-entries,$name-to-int-map)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="tcPr">
          <xsl:apply-templates select="($cals-entries[1]/@colspan, letex:cals-colspan($name-to-int-map, $cals-entries[1]/@namest, $cals-entries[1]/@nameend))[1], $cals-entries[1]/@class, ($cals-entries[1]/@rowsep, $cals-entries[1]/@colsep)[1], $cals-entries[1]/@css:*"  mode="tcPr" />
          <xsl:if test="$cals-entries[1][self::th] or $cals-entries[1]/ancestor::thead">
            <w:shd w:val="clear" w:color="auto" 
              w:fill="{replace( letex:current-color($cals-entries[1], 'grey', if ($cals-entries[1]/ancestor::thead) then 'medium' else 'light'), '#', '' )}"/>
          </xsl:if>
          <xsl:apply-templates select="$cals-entries[1]/@css:background-color" mode="tcPr"/>
        </xsl:variable>
        <xsl:variable name="pPr">
          <xsl:apply-templates select="$cals-entries[1]/para/@css:page-break-avoid" mode="props"/>
        </xsl:variable>
        <w:tc>
          <w:tcPr>
            <xsl:if test="exists($cals-entries[1]/@morerows) or exists($cals-entries[1]/@rowspan)">
              <w:vMerge w:val="restart" hub:morerows="{if (exists($cals-entries[1]/@morerows)) then $cals-entries[1]/@morerows else number($cals-entries[1]/@rowspan)-1}"/>
            </xsl:if>
            <xsl:if test="exists($cals-entries[1]/@namest) or exists($cals-entries[1]/@colspan)">
              <w:hMerge w:val="restart"/>
            </xsl:if>
            <xsl:if test="$tcPr">
              <xsl:sequence  select="$tcPr" />
            </xsl:if>
          </w:tcPr>
          <xsl:apply-templates select="$cals-entries[1]/node()" mode="hub:default"/>
        </w:tc>
        <xsl:if test="exists($cals-entries[1]/@namest) or exists($cals-entries[1]/@colspan)">
          <xsl:for-each select="1 to (xs:integer($cals-entries[1]/@colspan), xs:integer(letex:cals-colspan($name-to-int-map, $cals-entries[1]/@namest, $cals-entries[1]/@nameend)))[1]-1">
            <w:tc>
              <w:tcPr>
                <xsl:if test="exists($cals-entries[1]/@morerows) or exists($cals-entries[1]/@rowspan)">
                  <w:vMerge w:val="restart" hub:morerows="{if (exists($cals-entries[1]/@morerows)) then $cals-entries[1]/@morerows else number($cals-entries[1]/@rowspan)-1}"/>
                </xsl:if>
                <w:hMerge w:val="continue"/>
                <xsl:if test="$tcPr">
                  <xsl:sequence  select="$tcPr" />
                </xsl:if>
              </w:tcPr>
              <w:p>
                <xsl:if test="$pPr">
                  <w:pPr>
                    <xsl:sequence  select="$pPr" />
                  </w:pPr>
                </xsl:if>
              </w:p>
            </w:tc>
          </xsl:for-each>
        </xsl:if>
        <xsl:sequence select="letex:position-tcs($built-entries[position() gt 1],$cals-entries[position() gt 1],$name-to-int-map)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template  match="tr | row"  mode="hub:default">
    <w:tr>
      <xsl:variable  name="trPr">
        <xsl:apply-templates  select="@class | @css:height | @css:page-break-inside"  mode="trPr" />
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
        <xsl:apply-templates  select="(@colspan, letex:cals-colspan($name-to-int-map, @namest, @nameend))[1], @class, (@rowsep, @colsep)[1], @css:*"  mode="tcPr" />
        <xsl:if test="self::th or ../../self::thead">
          <w:shd w:val="clear" w:color="auto" 
            w:fill="{replace( letex:current-color(., 'grey', if(../../self::thead) then 'medium' else 'light'), '#', '' )}"/>
        </xsl:if>
        <xsl:apply-templates  select="@css:background-color"  mode="tcPr" />
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
					<w:p>
					  <xsl:variable name="pPr">
					    <xsl:apply-templates  select="para/@css:page-break-after" mode="props" />
					  </xsl:variable>
					  <xsl:if test="$pPr">
					    <w:pPr>
					      <xsl:sequence  select="$pPr" />
					    </w:pPr>
					  </xsl:if>
					</w:p>
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
    <w:gridSpan w:val="{. - 1}" />
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

  <xsl:template match="@colsep | @rowsep" mode="tcPr">
    <w:tcBorders>
      <xsl:for-each select="parent::*/@colsep | parent::*/@rowsep">
        <xsl:element name="w:{if (name(.)='colsep') then 'right' else 'bottom'}">
          <xsl:attribute name="w:val" select="if (.='0') then 'none' else 'single'"/>
        </xsl:element>
      </xsl:for-each>
    </w:tcBorders>
  </xsl:template>
  
  <xsl:template match="@css:width" mode="tcPr">
    <xsl:element name="w:tcW">
      <xsl:attribute name="w:w" select="if (matches(.,'pct$')) then replace(.,'pct$','') else if (matches(.,'pt$')) then number(replace(.,'pt$',''))*20 else '0'"/>
      <xsl:attribute name="w:type" select="if (matches(.,'pct$')) then 'pct' else if (matches(.,'pt$')) then 'dxa' else 'auto'"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@css:vertical-align" mode="tcPr">
    <w:vAlign w:val="{if (.='middle') then 'center' else .}"/>
  </xsl:template>

  <xsl:template match="@css:background-color" mode="tcPr">
    <w:shd w:val="clear" w:color="auto" w:fill="{.}"/>
  </xsl:template>

  <xsl:template match="@frame" mode="tblPr">
    <xsl:variable name="frame" as="xs:string *">
      <xsl:value-of select="if (.=('all','top','topbot','above','hsides','box','border')) then 'top:single' else 'top:none'"/>
      <xsl:value-of select="if (.=('all','bottom','topbot','below','hsides','box','border')) then 'bottom:single' else 'bottom:none'"/>
      <xsl:value-of select="if (.=('all','sides','lhs','vsides','box','border')) then 'left:single' else 'left:none'"/>
      <xsl:value-of select="if (.=('all','sides','rhs','vsides','box','border')) then 'right:single' else 'right:none'"/>
    </xsl:variable>
    <w:tblBorders>
      <xsl:for-each select="$frame">
        <xsl:element name="w:{tokenize(.,':')[1]}">
          <xsl:attribute name="w:val" select="tokenize(.,':')[last()]" />
        </xsl:element>
      </xsl:for-each>
    </w:tblBorders>
  </xsl:template>
  
  <xsl:template match="@css:text-align" mode="tblPr">
    <w:jc w:val="{.}"/>
  </xsl:template>

  <xsl:template match="@css:width" mode="tblPr">
    <xsl:element name="w:tblW">
      <xsl:attribute name="w:w" select="if (matches(.,'pct$')) then replace(.,'pct$','') else if (matches(.,'pt$')) then number(replace(.,'pt$',''))*20 else '0'"/>
      <xsl:attribute name="w:type" select="if (matches(.,'pct$')) then 'pct' else if (matches(.,'pt$')) then 'dxa' else 'auto'"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@css:height" mode="trPr">
    <xsl:element name="w:trHeight">
      <xsl:attribute name="w:val" select="if (matches(.,'pt$')) then number(replace(.,'pt$',''))*20 else ."/>
      <xsl:attribute name="w:h-rule" select="'at-least'"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@css:page-break-inside" mode="trPr">
    <xsl:if test=".='avoid'">
      <w:cantSplit/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template  match="@*"  mode="trPr tcPr tblPr"  priority="-4" />

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

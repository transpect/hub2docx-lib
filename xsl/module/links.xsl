<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl = "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs = "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc = "http://www.bacman.net/XSLdoc"
    xmlns:saxon = "http://saxon.sf.net/"
    xmlns:saxExtFn = "java:saxonExtensionFunctions"
    xmlns:hub = "http://transpect.io/hub"
    xmlns:xlink = "http://www.w3.org/1999/xlink"
    xmlns:css = "http://www.w3.org/1996/css"

    xmlns:o = "urn:schemas-microsoft-com:office:office"
    xmlns:mc = "http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m = "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:r = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:rel = "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:wp = "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon saxExtFn hub xlink o w m r rel wp css"
>


<!-- ================================================================================ -->
<!-- VARIABLES -->
<!-- ================================================================================ -->

  <!-- speed up the index-of() a little bit -->
  <xsl:variable  name="hyperlinks"  select="//link[@role eq 'uri' or @xlink:href]"/>


<!-- ================================================================================ -->
<!-- TEMPLATES -->
<!-- ================================================================================ -->

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


<!--  <xsl:template  match="anchor"  mode="hub:default">
    <xsl:if  test="node()">
      <xsl:message  terminate="yes" select="'ERROR: element &quot;anchor&quot; must not have any content!'"/>
    </xsl:if>
    <!-\- § has to be located within w:p ? -\->
    <w:bookmarkStart  w:id="{generate-id()}"  w:name="{@xml:id}"/>
    <!-\- there must be some content in a bookmark -\->
    <w:r>
      <w:t>&#xfeff;</w:t>
    </w:r>
    <w:bookmarkEnd w:id="{generate-id()}"/>
  </xsl:template>-->

  <xsl:template  match="anchor[not(matches(@xml:id,'^comment_'))]"  mode="hub:default">
    <xsl:if  test="node()">
      <xsl:message  terminate="yes" select="'ERROR: element &quot;anchor&quot; must not have any content!'"/>
    </xsl:if>
    <!-- § has to be located within w:p ? -->
    <w:bookmarkStart  w:id="{generate-id()}"  w:name="{(@xml:id, generate-id())[1]}">
      <!-- GI 2019-11-07: For a lookup in a corresponding docVar, it is important that an existing
        @xml:id be preserved. https://github.com/basex-gmbh/voktool-LingSoft/issues/311 -->
    </w:bookmarkStart>
  </xsl:template>
  
  <xsl:key name="by-id" match="*[@xml:id]" use="@xml:id" />
  
  <!--  keep 'start' and 'end' anchors from earlier docx conversion -->
   <xsl:template match="anchor[@role='start'][@xml:id]"  mode="hub:default">
     <xsl:apply-templates select="@xml:id" mode="hub:bookmark-start"/>
  </xsl:template>
  
  <xsl:template match="anchor[not(@role)]
                             [@xml:id]
                             [not(matches(@xml:id,'^comment_'))]
                             [not(key('by-id',concat(@xml:id,'_end')))]"  mode="hub:default">
    <xsl:apply-templates select="@xml:id" mode="hub:bookmark-start"/>
    <xsl:apply-templates select="@xml:id" mode="hub:bookmark-end"/>
  </xsl:template>
  
  <xsl:template match="anchor[@role='end'][@xml:id]"  mode="hub:default">
    <xsl:apply-templates select="@xml:id" mode="hub:bookmark-end"/>
  </xsl:template>
  
  <xsl:template match="anchor[@role='start' or not(@role)]/@xml:id" mode="hub:bookmark-start">
    <w:bookmarkStart w:id="{generate-id(parent::*/parent::*)}"  w:name="{.}"/>
  </xsl:template>
  
  <xsl:template match="anchor[@role='end' or not(@role)]/@xml:id" mode="hub:bookmark-end">
    <w:bookmarkEnd w:id="{generate-id(parent::*/parent::*)}"/>
  </xsl:template>

  <xsl:variable name="xref-text-before" as="xs:string"
    select="'['"/>
  <xsl:variable name="xref-text-after" as="xs:string"
    select="']'"/>

  <!-- Automatically resolved references to bibliography entries. 
       Should also handle biblioref in the future.
       -->
  <xsl:template  match="xref[@role eq 'bibref']"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="element(*)*"  tunnel="yes"/>
    <xsl:variable  name="targetNodes"  select="for $le in (@linkend, tokenize(@linkends, '\s+')) return key('by-id', $le, $root)" as="element(*)*"/>
    <xsl:variable name="bibref-rPr" as="node()*">
      <w:rPr>
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent" as="element(*)*"/>
          <xsl:with-param  name="new_rPrContent" as="element(w:rStyle)">
            <w:rStyle w:val="{$link-bibref-rstyle}"/>
          </xsl:with-param>
        </xsl:call-template>
      </w:rPr>
    </xsl:variable>
    <xsl:if test="not(preceding::text()[1][ends-with(., $xref-text-before)])">
      <w:r>
        <xsl:sequence select="$bibref-rPr"/>
        <w:t>
          <xsl:value-of select="$xref-text-before"/>
        </w:t>
      </w:r>
    </xsl:if>
    <xsl:for-each select="$targetNodes">
      <w:r>
        <w:fldChar w:fldCharType="begin"/>
      </w:r>
      <w:r>
        <xsl:variable name="bm" as="element(w:bookmarkStart)">
          <xsl:apply-templates select="." mode="hub:bookmark-start"/>
        </xsl:variable>
        <w:instrText xml:space="preserve"> REF <xsl:value-of select="$bm/@w:name"/> \w \h \* MERGEFORMAT </w:instrText>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="separate"/>
      </w:r>
      <w:r>
        <xsl:sequence select="$bibref-rPr"/>
        <w:t>
          <xsl:value-of select="index-of((//biblioentry union //bibliomixed)/@xml:id, @xml:id)"/>
        </w:t>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
      <xsl:if test="position() != last()">
        <w:r>
          <xsl:sequence select="$bibref-rPr"/>
          <w:t>
            <xsl:value-of select="','"/>
          </w:t>
        </w:r>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="not(following::text()[1][starts-with(., $xref-text-after)])">
      <w:r>
        <xsl:sequence select="$bibref-rPr"/>
        <w:t>
          <xsl:value-of select="$xref-text-after"/>
        </w:t>
      </w:r>
    </xsl:if>
  </xsl:template>

  <xsl:template  match="xref[
                          not(@role eq 'bibref') and 
                          (
                            not(@role eq 'internal' and @xrefstyle = ('page', 'pagera', 'pagerb')) or 
                            (@role eq 'internal' and not(@xrefstyle))
                          ) and 
                          @linkend[key('by-id', ., $root)/(@xreflabel[. ne ''] or title[normalize-space()])]
                        ]"  mode="hub:default">
    <xsl:variable  name="targetNode"  select="key('by-id', @linkend, $root)[1]"/>
    <xsl:variable  name="linktext" as="xs:string"
      select="if($targetNode/@xreflabel) then $targetNode/@xreflabel
              else string-join(($targetNode/title)[1]//text()[not(ancestor::*[self::footnote or self::indexterm])], '')"/>
    <w:r><w:fldChar w:fldCharType="begin"/></w:r>
    <w:r>
      <xsl:variable name="bm" as="element(w:bookmarkStart)">
        <xsl:apply-templates select="$targetNode" mode="hub:bookmark-start"/>
      </xsl:variable>
      <w:instrText xml:space="preserve"> HYPERLINK \l <xsl:value-of  select="$bm/@w:name"/> \o "<xsl:value-of  select="replace($linktext, '(&quot;)', '\\$1')"/>"</w:instrText>
    </w:r>
    <w:r><w:fldChar w:fldCharType="separate"/></w:r>
    <w:r>
      <w:t>
        <xsl:value-of  select="$linktext"/>
      </w:t>
    </w:r>
    <w:r><w:fldChar w:fldCharType="end"/></w:r>
  </xsl:template>

  <xsl:template  match="xref[@role eq 'internal' and @xrefstyle = ('page', 'pagera', 'pagerb')]"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="element(*)*" tunnel="yes"/>
    <xsl:variable  name="targetNode"  select="key('by-id', (@xlink:href, @linkend, @linkends)[1], $root)"/>
    <xsl:choose>
      <xsl:when  test="count( $targetNode) ne 1">
        <xsl:message  select="'ERROR: Target node of a link-element does not exist or is ambiguous.'"/>
        <xsl:message  terminate="no" select="."/>

        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param  name="rPrContent"  tunnel="yes" as="element(*)*">
            <xsl:call-template  name="mergeRunProperties">
              <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent" as="element(*)*"/>
              <xsl:with-param  name="new_rPrContent" as="element(w:rStyle)?">
                <xsl:if  test="@role eq 'bibref'">
                  <w:rStyle w:val="{$link-bibref-rstyle}"/>
                </xsl:if>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <w:r><w:t>p.&#x2009;</w:t></w:r>
        <w:r><w:fldChar w:fldCharType="begin"/></w:r>
        <xsl:variable name="bm" as="element(w:bookmarkStart)">
          <xsl:apply-templates select="$targetNode" mode="hub:bookmark-start"/>
        </xsl:variable>
        <w:r><w:instrText xml:space="preserve"> PAGEREF <xsl:value-of  select="$bm/@w:name"/> \h </w:instrText></w:r>
        <w:r><w:fldChar w:fldCharType="separate"/></w:r>
        <w:r><w:rPr><w:noProof/></w:rPr><w:t>??</w:t></w:r>
        <w:r><w:fldChar w:fldCharType="end"/></w:r>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:variable name="link-bibref-rstyle" as="xs:string?"
    select="'LiteraturverweisZchn'"/>
  <xsl:variable name="link-internal-rstyle" as="xs:string?"
    select="'InternalRef'"/>
  
  <xsl:template match="link[matches(@xlink:href, '^([a-z][a-z0-9+\-.]*)://')]" mode="hub:default_" priority="10">
    <!-- GI 2019-11-07: Deactivated because a) redundancy with field code HYPELRINKs that are still being generated
      inside and b) https://github.com/basex-gmbh/voktool-LingSoft/issues/311 (a VBA macro crashed when processing 
      HYPERLINKs wrapped in w:hyperlink -->
    <w:hyperlink>
      <xsl:next-match/>
    </w:hyperlink>
  </xsl:template>

  <xsl:template match="link" mode="hub:default">
    <xsl:param name="rPrContent" as="element(*)*" tunnel="yes"/>
    <xsl:variable name="targetNode" as="element(*)?"
      select="$root//*[ @xml:id eq current()/(@xlink:href, @linkend)]"/>
    <xsl:variable name="targetNode-corrected" as="element(*)?"
      select="if($targetNode/self::tgroup) 
              then $targetNode/(ancestor::table[1] | ancestor::informaltable[1]) 
              else $targetNode"/>
    <xsl:choose>
      <xsl:when test="not(@xlink:href) and count( $targetNode-corrected) ne 1">
        <xsl:message select="'ERROR: Target node of a link-element does not exist or is ambiguous. Target:', (@xlink:href, @linkend)"/>
        <xsl:message terminate="no" select="."/>

        <xsl:apply-templates select="node()" mode="#current" >
          <xsl:with-param name="rPrContent" tunnel="yes" as="element(*)*">
            <xsl:call-template name="mergeRunProperties">
              <xsl:with-param name="inherited_rPrContent" select="$rPrContent" as="element(*)*"/>
              <xsl:with-param name="new_rPrContent" as="element(w:rStyle)?">
                <xsl:if test="@role eq 'bibref'">
                  <w:rStyle w:val="{$link-bibref-rstyle}"/>
                </xsl:if>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="target" select="($targetNode-corrected/@xml:id, @linkend)[1] | @xlink:href" as="xs:string"/>
        <xsl:variable name="title" select="replace((@xlink:title, ., ' ')[1], '([&quot;»«])', '\\$1')" as="xs:string"/>
        <xsl:if test="@xml:id">
          <w:bookmarkStart w:id="{generate-id()}" w:name="{(@xml:id, generate-id())[1]}">
            <!-- GI 2019-11-07: For a lookup in a corresponding docVar, it is important that an existing
                  @xml:id be preserved. https://github.com/basex-gmbh/voktool-LingSoft/issues/311 -->
          </w:bookmarkStart>
        </xsl:if>
        <w:r>
          <w:fldChar w:fldCharType="begin"/>
        </w:r>
        <w:r>
          <xsl:choose>
            <xsl:when test="@xlink:href">
              <w:instrText xml:space="preserve"> HYPERLINK <xsl:value-of select="$target"/> \o "<xsl:value-of select="$title"/>"</w:instrText>
            </xsl:when>
            <!--<xsl:when test="@role = ('internal', 'bibref')">
              <w:instrText xml:space="preserve"> HYPERLINK \l bm_<xsl:value-of select="$targetNode-corrected/generate-id()"/>_ \o "<xsl:value-of select="$title"/>"</w:instrText>              
            </xsl:when>-->
            <xsl:otherwise>
              <!-- reverted from bm_<xsl:value-of select="$targetNode-corrected/generate-id()"/>_ because of
                a regression reported in https://github.com/basex-gmbh/voktool-LingSoft/issues/320 
              The bookmark IDs and corresponding docVars need to start with 'token_', otherwise a VBA 
              tool and other (complex) pipelines won’t work. -->
              <xsl:variable name="bm" as="element(w:bookmarkStart)">
                <xsl:apply-templates select="$targetNode-corrected" mode="hub:bookmark-start"/>
              </xsl:variable>
              <w:instrText xml:space="preserve"> HYPERLINK \l <xsl:value-of  select="$bm/@w:name"/> \o "<xsl:value-of select="$title"/>"</w:instrText>
            </xsl:otherwise>
          </xsl:choose>
        </w:r>
        <w:r>
          <w:fldChar w:fldCharType="separate"/>
        </w:r>
        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param name="rPrContent" tunnel="yes" as="element(*)*">
            <xsl:call-template name="mergeRunProperties">
              <xsl:with-param name="inherited_rPrContent" select="$rPrContent" as="element(*)*"/>
              <xsl:with-param name="new_rPrContent" as="element(w:rStyle)?">
                <xsl:choose>
                  <xsl:when test="@role eq 'bibref'">
                    <w:rStyle w:val="{$link-bibref-rstyle}"/>
                  </xsl:when>
                  <xsl:when test="@role eq 'internal'">
                    <w:rStyle w:val="{$link-internal-rstyle}"/>
                  </xsl:when>
                  <xsl:otherwise/>
                </xsl:choose>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
        <w:r>
          <w:fldChar w:fldCharType="end"/>
        </w:r>
        <xsl:if test="@xml:id">
          <w:bookmarkEnd w:id="{generate-id()}"/>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="documentRels" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- §§ profiling sinnvoll/nötig?! -->
  <xsl:template  match="link[@role eq 'uri' or @xlink:href]"  mode="documentRels footnoteRels">
    <xsl:param name="rels" as="xs:string*" tunnel="yes"/>
    <xsl:if test="matches( ., ' ' )">
      <xsl:message select="'WARNING: space in target replaced with underscore', ."/>
    </xsl:if>
    <xsl:variable name="Target" select="if( matches( ., ' ' ) ) then replace( ., ' ', '_' ) else ."/>
    <rel:Relationship Id="{index-of( $rels, generate-id(.))}"  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"  Target="{$Target}"  TargetMode="External"/>
  </xsl:template>

</xsl:stylesheet>

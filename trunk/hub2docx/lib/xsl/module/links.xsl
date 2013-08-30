<?xml version="1.0" encoding="UTF-8"?>

<!--
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
~     Authors: Gerrit Imsieke, Ralph Krüger                                                                             ~
~              (C) le-tex publishing services GmbH Leipzig (2010)                                                       ~
~                                                                                                                       ~
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-->

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
    xmlns:r		= "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink o w m r rel wp"
>


<!-- ================================================================================ -->
<!-- VARIABLES -->
<!-- ================================================================================ -->

  <!-- speed up the index-of() a little bit -->
  <xsl:variable  name="hyperlinks"  select="//link[@role eq 'uri' or (not(@role) and @xlink:href)]"/>


<!-- ================================================================================ -->
<!-- TEMPLATES -->
<!-- ================================================================================ -->

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


  <xsl:template  match="anchor"  mode="hub:default">
    <xsl:if  test="node()">
      <xsl:message  terminate="yes" select="'ERROR: element &quot;anchor&quot; must not have any content!'"/>
    </xsl:if>
    <!-- § has to be located within w:p ? -->
    <w:bookmarkStart  w:id="{generate-id()}"  w:name="bm_{generate-id()}_"/>
    <!-- there must be some content in a bookmark -->
    <w:r>
      <w:t>&#xfeff;</w:t>
    </w:r>
    <w:bookmarkEnd    w:id="{generate-id()}"/>
  </xsl:template>

  <xsl:key name="by-id" match="*[@xml:id]" use="@xml:id" />


  <!-- Automatically resolved references to bibliography entries. 
       Should also handle biblioref in the future.
       -->
  <xsl:template  match="xref[@role eq 'bibref']"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:variable  name="targetNodes"  select="for $le in (@linkend, tokenize(@linkends, '\s+')) return key('by-id', $le)" as="element(*)*"/>
    <w:r>
      <w:t>[</w:t>
    </w:r>
    <xsl:for-each select="$targetNodes">
      <w:r>
        <w:fldChar w:fldCharType="begin"/>
      </w:r>
      <w:r>
        <w:instrText xml:space="preserve"> REF bm_<xsl:value-of select="generate-id()"/>_ \w \h</w:instrText>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="separate"/>
      </w:r>
      <w:r>
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
          <xsl:with-param  name="new_rPrContent">
            <w:rStyle w:val="bibref"/>
          </xsl:with-param>
        </xsl:call-template>
        <w:t>
          <xsl:value-of select="index-of((//biblioentry union //bibliomixed)/@xml:id, @xml:id)"/>
        </w:t>
      </w:r>
      <w:r>
        <w:fldChar w:fldCharType="end"/>
      </w:r>
      <xsl:if test="position() != last()">
        <w:r>
          <w:t>
            <xsl:value-of select="','"/>
          </w:t>
        </w:r>
      </xsl:if>
    </xsl:for-each>
    <w:r>
      <w:t>]</w:t>
    </w:r>
  </xsl:template>

  <xsl:template  match="xref[@role eq 'internal' and @xrefstyle = ('page', 'pagera', 'pagerb')]"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:variable  name="targetNode"  select="key('by-id', @xlink:href)"/>
    <xsl:choose>
      <xsl:when  test="count( $targetNode) ne 1">
        <xsl:message  select="'ERROR: Target node of a link-element does not exist or is ambiguous.'"/>
        <xsl:message  terminate="no" select="."/>

        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param  name="rPrContent"  tunnel="yes">
            <xsl:call-template  name="mergeRunProperties">
              <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
              <xsl:with-param  name="new_rPrContent">
                <xsl:if  test="@role eq 'bibref'">
                  <w:rStyle w:val="LiteraturverweisZchn"/>
                </xsl:if>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <w:r><w:t>p.&#x2009;</w:t></w:r>
        <w:r><w:fldChar w:fldCharType="begin"/></w:r>
        <w:r><w:instrText xml:space="preserve"> PAGEREF bm_<xsl:value-of  select="$targetNode/generate-id()"/>_ \h </w:instrText></w:r>
        <w:r><w:fldChar w:fldCharType="separate"/></w:r>
        <w:r><w:rPr><w:noProof/></w:rPr><w:t>??</w:t></w:r>
        <w:r><w:fldChar w:fldCharType="end"/></w:r>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template  match="link[@role = ( 'internal', 'bibref' )]"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:choose>
      <xsl:when  test="@xlink:href eq 'id_NOTFOUND_DEADLINK'">
        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param  name="rPrContent"  tunnel="yes">
            <xsl:call-template  name="mergeRunProperties">
              <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
              <xsl:with-param  name="new_rPrContent">
                <!-- §§ this rStyle has still to be defined or replaced by another one! -->
                <w:rStyle  w:val="DeadHyperlink"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable  name="targetNode"  select="//*[ @xml:id eq current()/@xlink:href]"/>
        <xsl:choose>
          <xsl:when  test="count( $targetNode) ne 1">
            <xsl:message  select="'ERROR: Target node of a link-element does not exist or is ambiguous.'"/>
            <xsl:message  terminate="no" select="."/>

            <xsl:apply-templates  select="node()"  mode="#current" >
              <xsl:with-param  name="rPrContent"  tunnel="yes">
                <xsl:call-template  name="mergeRunProperties">
                  <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
                  <xsl:with-param  name="new_rPrContent">
                    <xsl:if  test="@role eq 'bibref'">
                      <w:rStyle w:val="LiteraturverweisZchn"/>
                    </xsl:if>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:apply-templates>

          </xsl:when>
          <xsl:otherwise>
            <!-- § This stuff has to be located within w:p! Is this guaranteed? -->

<!--             <w:r> -->
<!--               <w:t>p.&#xa0;</w:t> -->
<!--             </w:r> -->

            <w:r>
              <w:fldChar w:fldCharType="begin"/>
            </w:r>

            <w:r>
              <w:instrText xml:space="preserve"> HYPERLINK \l bm_<xsl:value-of  select="$targetNode/generate-id()"/>_ \o "<xsl:value-of  select="string-join((., if(@role eq 'bibref') then () else ''), ' ')"/>"</w:instrText>
            </w:r>

            <w:r>
              <w:fldChar w:fldCharType="separate"/>
            </w:r>

            <xsl:apply-templates  select="node()"  mode="#current" >
              <xsl:with-param  name="rPrContent"  tunnel="yes">
                <xsl:call-template  name="mergeRunProperties">
                  <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
                  <xsl:with-param  name="new_rPrContent">
                    <xsl:if  test="@role eq 'bibref'">
                      <w:rStyle w:val="bibref"/>
                    </xsl:if>
                  </xsl:with-param>
                </xsl:call-template>
              </xsl:with-param>
            </xsl:apply-templates>

            <w:r>
              <w:fldChar w:fldCharType="end"/>
            </w:r>

          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template  match="link[not(@role)][@linkend]"  mode="hub:default" priority="3">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <xsl:variable  name="targetNode"  select="key('by-id', @linkend)"/>
    <xsl:choose>
      <xsl:when  test="count( $targetNode) ne 1">
        <xsl:message  select="'ERROR: Target node of a link-element does not exist or is ambiguous (internal @linkend link).'"/>
        <xsl:message  terminate="no" select="."/>
        
        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param  name="rPrContent"  tunnel="yes">
            <xsl:call-template  name="mergeRunProperties">
              <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
              <xsl:with-param  name="new_rPrContent">
                <w:rStyle w:val="InternalRef"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <w:r>
          <w:fldChar w:fldCharType="begin"/>
        </w:r>
        
        <w:r>
          <w:instrText xml:space="preserve"> HYPERLINK \l bm_<xsl:value-of  select="$targetNode/generate-id()"/>_ \o "<xsl:value-of  select="string-join((., if(@role eq 'bibref') then () else ''), ' ')"/>"</w:instrText>
        </w:r>

        <w:r>
          <w:fldChar w:fldCharType="separate"/>
        </w:r>

        <xsl:apply-templates  select="node()"  mode="#current" >
          <xsl:with-param  name="rPrContent"  tunnel="yes">
            <xsl:call-template  name="mergeRunProperties">
              <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
              <xsl:with-param  name="new_rPrContent">
                <w:rStyle w:val="InternalRef"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:apply-templates>

        <w:r>
          <w:fldChar w:fldCharType="end"/>
        </w:r>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template  match="link[@role eq 'uri' or (not(@role) and @xlink:href)]"  mode="hub:default">
    <xsl:param  name="rPrContent"  as="node()*"  tunnel="yes"/>
    <w:hyperlink  r:id="{index-of( $hyperlinks, .)}"  w:history="1">
      <xsl:apply-templates  select="node()"  mode="#current" >
        <xsl:with-param  name="rPrContent"  tunnel="yes">
          <xsl:call-template  name="mergeRunProperties">
            <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"/>
            <xsl:with-param  name="new_rPrContent">
              <w:rStyle  w:val="Hyperlink"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:with-param>
      </xsl:apply-templates>
    </w:hyperlink>
  </xsl:template>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="documentRels" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- §§ profiling sinnvoll/nötig?! -->
  <xsl:template  match="link[@role eq 'uri' or (not(@role) and @xlink:href)]"  mode="documentRels">
		<xsl:if test="matches( ., ' ' )">
			<xsl:message select="'WARNING: space in target replaced with underscore', ."/>
		</xsl:if>
		<xsl:variable name="Target" select="if( matches( ., ' ' ) ) then replace( ., ' ', '_' ) else ."/>
    <rel:Relationship Id="{index-of( $hyperlinks, .)}"  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"  Target="{$Target}"  TargetMode="External"/>
  </xsl:template>

  <xsl:template  match="node()"  mode="documentRels">
    <xsl:apply-templates  mode="#current" />
  </xsl:template>


</xsl:stylesheet>
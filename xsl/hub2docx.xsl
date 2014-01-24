<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub = "http://www.le-tex.de/namespace/docx2hub"
  xmlns:hub = "http://www.le-tex.de/namespace/hub"
  xmlns:dbk = "http://docbook.org/ns/docbook"
  xmlns:css = "http://www.w3.org/1996/css"
  xmlns:letex = "http://www.le-tex.de/namespace"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  
  xpath-default-namespace = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs docx2hub hub"
  version="2.0">
  
  <xsl:import href="http://transpect.le-tex.de/docx_modify/xsl/identity.xsl"/>
  <xsl:import href="http://transpect.le-tex.de/docx_modify/xsl/props.xsl"/>
  <xsl:import href="http://transpect.le-tex.de/xslt-util/lengths/lengths.xsl"/>
  <xsl:import href="http://transpect.le-tex.de/xslt-util/colors/colors.xsl"/>
  
  <xsl:import href="module/lib_catch-all.xsl"/>
  <xsl:import href="module/lib_color.xsl"/>
  <xsl:import href="module/lib_query.xsl"/>
  <xsl:import href="module/lib_scope.xsl"/>
  <xsl:import href="module/lib_props.xsl"/>

  <xsl:import href="module/comments.xsl"/>
  <xsl:import href="module/text-runs.xsl"/>
  <xsl:import href="module/document-structure.xsl"/>
  <xsl:import href="module/para.xsl"/>
  <xsl:import href="module/bibliography.xsl"/>
  <xsl:import href="module/equation.xsl"/>
  <xsl:import href="module/footnote.xsl"/>
  <xsl:import href="module/glossary.xsl"/>
  <xsl:import href="module/images.xsl"/>
  <xsl:import href="module/index.xsl"/>
  <xsl:import href="module/links.xsl"/>
  <xsl:import href="module/lists.xsl"/>
  <xsl:import href="module/table.xsl"/>
  <xsl:import href="module/foreign.xsl"/>
  <xsl:import href="module/header.xsl"/>
  <xsl:import href="module/footer.xsl"/>
  <xsl:import href="module/merge-with-template.xsl"/>


  <xsl:param  name="a3paper" select="'no'"/>					<!-- DIN A3 paper -->
  <xsl:param  name="heading-prefix" select="'Heading'" as="xs:string"/> <!-- Heading w:styleId prefix; use 'berschrift' for German normal.dot -->
  <xsl:param  name="landscape" select="'no'"/>				<!-- page orientation landscape -->

  <!-- remove header and footer from inner word document: see modules header.xsl and footer.xsl -->
  <xsl:template match="*[@css:page][not(parent::css:page)][letex:is-header(.)]" mode="hub:default" priority="2000"/>
  <xsl:template match="*[@css:page][not(parent::css:page)][letex:is-footer(.)]" mode="hub:default" priority="2000"/>  

  <!-- remove elements with css:display="none" -->
  <xsl:template  match="*[@css:display eq 'none']"  mode="hub:default" priority="2000">
    <xsl:choose>
      <xsl:when test="not(/*/info/keywordset[@role eq 'hub']
                                   /keyword[@role eq 'docx2hub:remove-css-display-none-elements'])
                      or
                      /*/info/keywordset[@role eq 'hub']
                                /keyword[@role eq 'docx2hub:remove-css-display-none-elements'] = (
                                  'true', 'yes'
                                )" />
      <xsl:otherwise>
        <xsl:next-match />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- docx2hub error messages such as 
    <letex:comment xmlns:letex="http://www.le-tex.de/namespace" srcpath="">W2D_601: "Zeichen aus Font 'Wingdings 2 (0xF0BD)' kann nicht richtig dargestellt werden."</letex:comment>
    -->
  <xsl:template match="letex:comment" mode="hub:default"/>

  <xsl:template match="@xml:base" mode="hub:merge">
    <xsl:apply-templates select="." mode="docx2hub:modify"/>
  </xsl:template>

</xsl:stylesheet>

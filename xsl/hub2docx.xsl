<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml"
  xmlns:w16cid="http://schemas.microsoft.com/office/word/2016/wordml/cid"
  xmlns:w16se="http://schemas.microsoft.com/office/word/2015/wordml/symex" xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:ct="http://schemas.openxmlformats.org/package/2006/content-types"  xmlns:docx2hub="http://transpect.io/docx2hub"
  xmlns:hub = "http://transpect.io/hub"
  xmlns:tr = "http://transpect.io"
  xmlns:dbk = "http://docbook.org/ns/docbook"
  xmlns:css = "http://www.w3.org/1996/css"
  xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xpath-default-namespace = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs docx2hub hub tr rel mml"
  version="2.0">
  
  <xsl:import href="http://transpect.io/docx_modify/xsl/identity.xsl"/>
  <xsl:import href="http://transpect.io/docx_modify/xsl/props.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/lengths/xsl/lengths.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/mime-type/xsl/mime-type.xsl"/>
  <xsl:import href="http://transpect.io/xslt-util/colors/xsl/colors.xsl"/>
  
  <xsl:import href="module/lib_catch-all.xsl"/>
  <xsl:import href="module/lib_query.xsl"/>
  <xsl:import href="module/lib_scope.xsl"/>
  <xsl:import href="module/lib_props.xsl"/>

  <xsl:import href="module/comments.xsl"/>
  <xsl:import href="module/text-runs.xsl"/>
  <xsl:import href="module/para.xsl"/>
  <xsl:import href="module/document-structure.xsl"/>
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
  <!-- Heading w:styleId prefix; use 'berschrift' for German normal.dot, 'Heading' for english normal.dot
       default: 'berschrift' - will be translated to 'Heading' for non-german normal.dot templates -->
  <xsl:param  name="heading-prefix" select="'berschrift'" as="xs:string"/>
  <xsl:param  name="landscape" select="'no'"/>				<!-- page orientation landscape -->
  <xsl:param  name="template-lang" select="'en'"/>				<!-- language of the docx template. Important for default Style names -->
  <!-- render static index list -->
  <xsl:param name="render-index-list" select="'no'" as="xs:string?"/>
  <!--param create-and-map-styles-not-in-template:
      Create new styles in generated Word file out of given css:rules/css:rule elements in the source Hub XML document.
      All (used) styles listed there will be mapped.-->
  <xsl:param name="create-and-map-styles-not-in-template" select="'no'" as="xs:string?"/>
  <xsl:param name="collection-uri" as="xs:string?" select="()"/>
  
  <xsl:variable name="footnote-bookmark-prefix" as="xs:string"
    select="'FN_'"/>
  <xsl:param name="create-title-bookmarks" select="'yes'" as="xs:string"/>

  <!-- remove header and footer from inner word document: see modules header.xsl and footer.xsl -->
  <xsl:template match="*[@css:page][not(parent::css:page)][tr:is-header(.)]" mode="hub:default" priority="2000"/>
  <xsl:template match="*[@css:page][not(parent::css:page)][tr:is-footer(.)]" mode="hub:default" priority="2000"/>  

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
    <tr:comment xmlns:tr="http://transpect.io" srcpath="">W2D_601: "Zeichen aus Font 'Wingdings 2 (0xF0BD)' kann nicht richtig dargestellt werden."</tr:comment>
    -->
  <xsl:template match="tr:comment" mode="hub:default"/>

  <xsl:template match="@xml:base" mode="hub:merge">
    <xsl:apply-templates select="." mode="docx2hub:modify"/>
  </xsl:template>
  
  <xsl:template match="@srcpath" mode="hub:merge"/>
  
  <xsl:template match="anchor[@role=('w14:paraId','w14:textId')]" mode="hub:default">
    <xsl:attribute name="{@role}" select="replace(@xml:id,'(text|para)Id_','')"/>
  </xsl:template>

</xsl:stylesheet>

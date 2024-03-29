<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink o w m wp r css"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="bibliography"  mode="hub:default" >
    <xsl:apply-templates  select="node()"  mode="#current" />
  </xsl:template>

  <xsl:template  match="bibliodiv"  mode="hub:default" >
    <xsl:apply-templates  mode="#current" />
  </xsl:template>

  <xsl:template  match="bibliolist"     mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="bibliomixed/collab | 
                        bibliomixed/citetitle | 
                        bibliomixed/subtitle | 
                        bibliomixed/title | 
                        bibliomixed/pubdate | 
                        bibliomixed/orgname | 
                        bibliomixed/collab/orgname |
                        lineage |
                        honorific | 
                        personname | 
                        othername |
                        surname | 
                        firstname | 
                        seriesvolnums | 
                        issuenum | 
                        date | 
                        edition | 
                        citebiblioid | 
                        person | 
                        bibliomixed/publishername |  
                        bibliomixed/address" mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>
  
  
  <xsl:template  match="biblioentry" mode="hub:default">
    <xsl:apply-templates mode="#current" />
  </xsl:template>

  <xsl:template  match="bibliomixed"  mode="hub:default">
    <xsl:variable  name="bibliomixedId"  select="(@xml:id, generate-id())[1]"/>
    <xsl:apply-templates select="." mode="hub:bookmark-start"/>
    <w:p>
      <xsl:call-template name="hub:pPr"/>
      <xsl:apply-templates  select="node()"  mode="#current" />
    </w:p>
    <xsl:apply-templates select="." mode="hub:bookmark-end"/>
  </xsl:template>
  
  <xsl:template match="bibliomixed[@xml:id]" mode="hub:bookmark-start">
    <w:bookmarkStart w:id="{@xml:id}"  w:name="bm_{@xml:id}_"/>
  </xsl:template>
  
  <xsl:template match="bibliomixed[@xml:id]" mode="hub:bookmark-end">
    <w:bookmarkEnd w:id="{@xml:id}"/>
  </xsl:template>
  
  <xsl:template  match="bibliomixed"  mode="hub:style-name">
    <w:pStyle w:val="{(@role, 'bib')[1]}"/>
  </xsl:template>

  <xsl:template match="bibliomisc/@role[. = 'numberedRef']" mode="props">
    <w:pStyle w:val="bibnum"/>
    <w:numPr>
      <w:ilvl w:val="0"/>
      <w:numId w:val="{tr:getNumId( ancestor::*[local-name() = ( 'itemizedlist' , 'orderedlist', 'bibliography', 'bibliodiv' )][1]/generate-id() )}" />
    </w:numPr>
  </xsl:template>

  <xsl:template  match="bibliomisc" mode="hub:default">
    <w:p>
      <xsl:call-template name="hub:pPr">
        <xsl:with-param name="default-pPrs" as="element(w:pStyle)?" tunnel="yes">
          <xsl:if test="not(@role = 'numberedRef')">
            <w:pStyle w:val="bib"/>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
      <xsl:apply-templates mode="#current" />
    </w:p>
  </xsl:template>


</xsl:stylesheet>

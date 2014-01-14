<?xml version="1.0" encoding="UTF-8"?>
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
    xmlns:docx2hub      = "http://www.le-tex.de/namespace/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xpath-default-namespace = "http://docbook.org/ns/docbook"
    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn dbk xlink o w m r docx2hub"
>

  <!-- in text-runs.xsl: -->
  <!--<xsl:template match="*[@role = 'hub:foreign']" mode="hub:default">
    <xsl:apply-templates mode="hub:foreign"/>
  </xsl:template>-->
  
  <xsl:template match="* | w:drawing | w:txbxContent | w:pict" mode="hub:foreign">
    <xsl:element name="{name()}" namespace="{namespace-uri-from-QName(node-name(.))}">
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="@*" mode="hub:foreign">
    <xsl:copy/>
  </xsl:template>
  
  <xsl:template match="w:*" mode="hub:foreign">
    <xsl:apply-templates select="." mode="hub:default"/>
  </xsl:template>
  
  <xsl:template match="w:txbxContent[dbk:*]" mode="hub:foreign">
    <xsl:element name="{name()}" namespace="{namespace-uri-from-QName(node-name(.))}">
      <xsl:apply-templates select="@*, node()" mode="hub:default"/>
    </xsl:element>
  </xsl:template>
  

</xsl:stylesheet>

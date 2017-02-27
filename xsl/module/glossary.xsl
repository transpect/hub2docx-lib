<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:css = "http://www.w3.org/1996/css"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon saxExtFn hub xlink o w m wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ §§§ still to implement §§§ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->

  <xsl:template  match="/glossary"  mode="hub:default" priority="3">
    <w:root_converted>
      <w:document>
        <w:body>
          <xsl:call-template name="build-glossary"/>
        </w:body>
      </w:document>
    </w:root_converted>
  </xsl:template>

  <xsl:template  match="glossary[glossentry] | glossary/glossdiv"  name="build-glossary" mode="hub:default">
    <xsl:message  select="if(self::glossdiv) then '...Glossary section:' else '...Glossary:', string-join(title//text()[not(ancestor::indexterm)], '')"/>
    <xsl:apply-templates  select="title"  mode="#current" />
    <xsl:variable name="glossary-table">
      <xsl:apply-templates select="." mode="glossary2table"/>
    </xsl:variable>
    <xsl:variable name="custom-tblPrContent" as="element(*)*">
      <w:tblStyle w:val="GlossaryTable"/>
      <w:tblW w:w="0" w:type="auto"/>
      <w:tblLook w:val="01E0"/>
      <w:tblBorders/>
    </xsl:variable>
    <xsl:variable name="name-to-int-map" as="document-node(element(map))">
      <xsl:document>
        <map xmlns="http://docbook.org/ns/docbook">
          <item key="c1" val="1"/>
          <item key="c2" val="2"/>
        </map>
      </xsl:document>
    </xsl:variable>
    <xsl:apply-templates  select="$glossary-table"  mode="#current">
      <xsl:with-param name="tblPrContent" tunnel="yes" select="$custom-tblPrContent" />
      <xsl:with-param name="name-to-int-map" tunnel="yes" select="$name-to-int-map"/>
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="glossary | glossdiv" mode="glossary2table">
    <informaltable xmlns="http://docbook.org/ns/docbook"  css:width="100%">
      <tbody xmlns="http://docbook.org/ns/docbook">
        <xsl:apply-templates mode="#current" />
      </tbody>
    </informaltable>
  </xsl:template>

  <xsl:template match="title" mode="glossary2table" />

  <xsl:template match="glossentry" mode="glossary2table">
    <row xmlns="http://docbook.org/ns/docbook">
      <xsl:apply-templates mode="#current" />
    </row>
  </xsl:template>

  <xsl:template match="glossterm" mode="glossary2table">
    <entry xmlns="http://docbook.org/ns/docbook" css:width="20%">
      <para>
        <xsl:sequence select="node()" />
      </para>
    </entry>
  </xsl:template>

  <xsl:template match="glossdef" mode="glossary2table">
    <entry xmlns="http://docbook.org/ns/docbook" css:width="80%">
      <xsl:sequence select="node()" />
    </entry>
  </xsl:template>

</xsl:stylesheet>

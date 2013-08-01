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

  <!--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ §§§ still to implement §§§ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~-->

  <xsl:template  match="glossary"  mode="hub:default">
    <xsl:message  select="'...Glossary: ', string-join(title//text()[not(ancestor::indexterm)], '')"/>
    <xsl:apply-templates  select="title"  mode="#current" />
    <xsl:variable name="glossary-table">
      <xsl:apply-templates select="." mode="glossary2table" />
    </xsl:variable>
    <xsl:variable name="custom-tblPrContent" as="element(*)*">
      <w:tblStyle w:val="GlossaryTable"/>
      <w:tblW w:w="0" w:type="auto"/>
      <w:tblLook w:val="01E0"/>
      <w:tblBorders/>
    </xsl:variable>
    <xsl:apply-templates  select="$glossary-table"  mode="#current">
      <xsl:with-param name="tblPrContent" tunnel="yes" select="$custom-tblPrContent" />
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="glossary" mode="glossary2table">
    <informaltable xmlns="http://docbook.org/ns/docbook">
      <tbody xmlns="http://docbook.org/ns/docbook">
        <xsl:apply-templates mode="#current" />
      </tbody>
    </informaltable>
  </xsl:template>

  <xsl:template match="title" mode="glossary2table" />

  <xsl:template match="glossentry" mode="glossary2table">
    <tr xmlns="http://docbook.org/ns/docbook">
      <xsl:apply-templates mode="#current" />
    </tr>
  </xsl:template>

  <xsl:template match="glossterm" mode="glossary2table">
    <th xmlns="http://docbook.org/ns/docbook">
      <para>
        <xsl:copy-of select="node()" />
      </para>
    </th>
  </xsl:template>

  <xsl:template match="glossdef" mode="glossary2table">
    <td xmlns="http://docbook.org/ns/docbook">
      <xsl:copy-of select="node()" />
    </td>
  </xsl:template>



</xsl:stylesheet>

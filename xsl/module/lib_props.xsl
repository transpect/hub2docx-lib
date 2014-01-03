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
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn dbk xlink o w m wp r"
>


  <xsl:function name="letex:merge-props" as="element(*)*">
    <xsl:param name="custom-props"    as="element(*)*" />
    <xsl:param name="default-props"    as="element(*)*" />
    <xsl:variable name="result" as="element(*)*">
    <xsl:for-each select="distinct-values(for $prop in ($custom-props union $default-props) return name($prop))">
      <xsl:choose>
        <xsl:when test="$custom-props/self::*[name() = current()]">
          <xsl:sequence select="$custom-props/self::*[name() = current()]" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="$default-props/self::*[name() = current()]" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    </xsl:variable>
    <xsl:sequence select="$result" />
  </xsl:function>

  <!-- Establish OOXML schema compliant prop sort order (which is, typically, alphabetical) -->
  <xsl:template match="@* | *" mode="letex:propsortkey" as="xs:integer">
    <xsl:sequence select="1000 * (string-to-codepoints((prefix-from-QName(node-name(.)), '_')[1]))[1]
      + 10 * (string-to-codepoints(local-name(.)))[1]"/>
  </xsl:template>
  
  

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:letex		= "http://www.le-tex.de/namespace"
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex dbk xlink o w m wp r"
>

  <!-- Tests whether $elt is immediately contained in $ancestor-elt 
       (that is, in the same document, in the same Cell, etc.). 
       This function works both in OOXML and in Hub XML contexts.
       -->
  <xsl:function name="letex:same-scope" as="xs:boolean">
    <xsl:param name="elt" as="node()" />
    <xsl:param name="ancestor-elt" as="element(*)" />
    <xsl:sequence select="not(
                            $elt/ancestor::*[letex:is-scope-origin(.)]
                                            [some $a in ancestor::* satisfies ($a is $ancestor-elt)]
                          )" />
  </xsl:function>
  
  <xsl:function name="letex:is-scope-origin" as="xs:boolean">
    <xsl:param name="elt" as="element(*)" />
    <xsl:sequence select="exists($elt/(w:document | self::w:tc | self::entry))" />
  </xsl:function>
  

</xsl:stylesheet>

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


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="document" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:function name="letex:color" as="xs:string?">
    <xsl:param name="role"    as="xs:string?" />
    <xsl:param name="variant" as="xs:string?" />

    <xsl:variable  name="name"  select="distinct-values(tokenize($role, '\s+')[. = document('')//letex:colors/letex:color/@name])"  as="xs:string?"/>
    <xsl:sequence select="document('')//letex:colors/letex:color[@name = $name]/@*[name() = ($variant, 'dark')[1]]" />
  </xsl:function>

  <xsl:function name="letex:current-color" as="xs:string?">
    <xsl:param name="context" as="node()" />
    <xsl:param name="fallback" as="xs:string?" />
    <xsl:param name="variant" as="xs:string?" />
    <xsl:variable name="the-variant" select="if ($variant = ('light', 'medium', 'dark')) then $variant else ()" />
    <xsl:value-of select="(for $s in $context/ancestor-or-self::section
                             return letex:color($s/@role, $the-variant), 
                           if ($fallback ne '') 
                             then letex:color($fallback, $the-variant)
                             else ()
                          )[1]" />
  </xsl:function>


  <letex:colors>
    <letex:color name="grey"    light="#eeeeee"  medium="#dddddd"  dark="#777777" />
    <letex:color name="blue"    light="#dfe6f3"  medium="#c4cfe7"  dark="#00427e" />
    <letex:color name="green"   light="#e2f1de"  medium="#9bd4aa"  dark="#0a9739" />
    <letex:color name="orange"  light="#e1b59c"  medium="#e18d5c"  dark="#e16721" />
    <letex:color name="red"     light="#e9bca6"  medium="#ce898a"  dark="#a0191e" />
    <letex:color name="yellow"  light="#ffff00"  medium="#ffffe0"  dark="#888800" />
    <letex:color name="white"   light="#ffffff"  medium="#ffffff"  dark="#ffffff" />
    <letex:color name="black"   light="#000000"  medium="#000000"  dark="#000000" />
  </letex:colors>

  <xsl:function name="letex:retrieve-color-attribute-val" as="xs:string">
    <xsl:param name="css-color-attrib" as="attribute()?"/>
    <xsl:variable name="hex-code" as="xs:string"
      select="replace(letex:convert-css-color-attr($css-color-attrib, 'hex'), '^#', '')"/>
    <xsl:choose>
      <xsl:when test="matches($hex-code, '^[0-9a-fA-F]{6}$')">
        <xsl:sequence select="$hex-code"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'Input color pattern', xs:string($css-color-attrib), 'not convertible. Implement me in colors/colors.xsl! Falling back to &quot;auto&quot; (may be invalid).'"/>
        <xsl:sequence select="'auto'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>

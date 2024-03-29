<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:dbk		= "http://docbook.org/ns/docbook"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn dbk xlink o w m wp r"
>

  <xsl:function name="tr:is-header" as="xs:boolean">
    <xsl:param name="node" as="element()" />
    <xsl:sequence select="boolean(
                            root($node)/*/info/css:rules[
                              css:rule[
                                @layout-type eq 'object'
                              ]/@name = $node/@role
                              and
                              css:page[
                                css:page-margin-box[
                                  @location eq 'top-center'
                                ]
                              ]/@name = $node/@css:page
                            ]
                          )"/>
  </xsl:function>

  <xsl:function name="tr:is-footer" as="xs:boolean">
    <xsl:param name="node" as="element()" />
    <xsl:sequence select="boolean(
                            root($node)/*/info/css:rules[
                              css:rule[
                                @layout-type eq 'object'
                              ]/@name = $node/@role
                              and
                              css:page[
                                css:page-margin-box[
                                  @location eq 'bottom-center'
                                ]
                              ]/@name = $node/@css:page
                            ]
                          )"/>
  </xsl:function>

  <xsl:function name="tr:text" as="xs:string?">
    <xsl:param name="node" as="element(*)?" />
    <xsl:variable name="out">
      <xsl:apply-templates select="$node" mode="extract-text" />
    </xsl:variable>
    <xsl:value-of select="$out"/>
  </xsl:function>

  <xsl:template  match="*"  mode="extract-text"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

  <xsl:template  match="indexterm"  mode="extract-text" />

</xsl:stylesheet>

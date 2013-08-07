<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:docx2hub = "http://www.le-tex.de/namespace/docx2hub"
  xmlns:hub = "http://www.le-tex.de/namespace/hub"
  xmlns:dbk = "http://docbook.org/ns/docbook"

  xpath-default-namespace = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs docx2hub hub"
  version="2.0">

  <!-- mode merge:
       collection()/w:root_converted: converted hub (see mode hub:default)
       collection()/w:root: docx template w:root
  -->

  <xsl:template match="/*" mode="hub:merge">
    <w:root>
      <xsl:apply-templates select="collection()/w:root/node()" mode="#current">
        <xsl:with-param name="footnoteIdOffset" tunnel="yes"
          select="(xs:integer(max(collection()/w:root/w:footnotes/w:footnote/@w:id)), 0)[1]" />
        <xsl:with-param name="relationIdOffset" tunnel="yes"
          select="max( for $rId in ( collection()/w:root/w:docRels//r:Relationships/w:Relationship/@Id ) return number( substring( $rId, 4)))" />
      </xsl:apply-templates>
    </w:root>
  </xsl:template>

  <xsl:template match="w:document" mode="hub:merge">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@xml:base" mode="docx2hub:modify"/>
      <xsl:apply-templates select="collection()/w:root_converted/w:document/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- footnote changes/additions -->

  <xsl:template match="w:footnotes" mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="hub:merge" />
      <xsl:apply-templates select="collection()/w:root_converted/w:footnotes/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match=" //w:root_converted//w:footnote/@w:id
          | //w:root_converted//w:footnoteReference/@w:id
          | //w:root_converted//w:bookmarkEnd[
                                  preceding-sibling::*[1][
                                    self::w:r[
                                      w:footnoteReference
                                    ]
                                  ]
                                ]/@w:id">
    <xsl:param name="footnoteIdOffset" tunnel="yes" />
    <xsl:attribute name="w:id" select=". + $footnoteIdOffset"/>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//w:bookmarkStart[
                                 following-sibling::*[1][
                                   self::w:r[
                                     w:footnoteReference
                                   ]
                                 ]
                               ]">
    <xsl:param name="footnoteIdOffset" tunnel="yes" />
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:attribute name="w:id" select="@w:id + $footnoteIdOffset"/>
      <xsl:attribute name="w:name" select="concat(@w:name, '_', $footnoteIdOffset)"/>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>


  <!-- relationship changes/additions -->

  <xsl:template 
    mode="hub:merge"
    match="w:hyperlink/@r:idd">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:attribute name="r:id" select="$relationIdOffset + . "/>
  </xsl:template>


  <xsl:template 
    match="* | @*" 
    mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:rel="http://schemas.openxmlformats.org/package/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:ct="http://schemas.openxmlformats.org/package/2006/content-types"
  xmlns:docx2hub = "http://www.le-tex.de/namespace/docx2hub"
  xmlns:hub = "http://www.le-tex.de/namespace/hub"
  xmlns:hub2docx = "http://www.le-tex.de/namespace/hub2docx"
  xmlns:dbk = "http://docbook.org/ns/docbook"
  xmlns:v             = "urn:schemas-microsoft-com:vml"
  
  xpath-default-namespace = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs docx2hub hub"
  version="2.0">

  <!-- mode merge:
       collection()/w:root_converted: converted hub (see mode hub:default)
       collection()/w:root: docx template w:root
  -->

  <!-- "initial" template:
       apply nodes of docx template in mode hub:merge
  -->
  <xsl:template match="/*" mode="hub:merge">
    <w:root>
      <xsl:apply-templates select="collection()/w:root/node()" mode="#current">
        <xsl:with-param name="footnoteIdOffset" tunnel="yes"
          select="(xs:integer(max(collection()/w:root/w:footnotes/w:footnote/@w:id)), 0)[1]" />
        <xsl:with-param name="commentIdOffset" tunnel="yes"
          select="(xs:integer(max(collection()/w:root/w:comments/w:comment/@w:id)), 0)[1]" />
        <xsl:with-param name="relationIdOffset" tunnel="yes"
          select="max( for $rId in ( collection()/w:root/w:docRels//rel:Relationships/rel:Relationship/@Id ) return number( substring( $rId, 4)))" />
      </xsl:apply-templates>
    </w:root>
  </xsl:template>

  <xsl:template match="w:document" mode="hub:merge">
    <xsl:variable name="xml-base-modified" as="attribute(xml:base)">
      <xsl:apply-templates select="@xml:base" mode="docx2hub:modify"/>
    </xsl:variable>
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="$xml-base-modified, collection()/w:root_converted/w:document/node()" mode="#current"/>
    </xsl:copy>

    <!-- no footnotes in template: create the footnote root element separately for converted hub footnotes -->
    <xsl:if test="not(../w:footnotes)  and 
                  collection()/w:root_converted/w:footnotes/node()">
      <w:footnotes xml:base="{replace($xml-base-modified, 'document\.xml', 'footnotes.xml')}">
        <xsl:apply-templates select="collection()/w:root_converted/w:footnotes/node()" mode="#current"/>
      </w:footnotes>
    </xsl:if>
    <xsl:if test="not(../w:comments)  and
                  collection()/w:root_converted/w:comments/node()">
      <w:comments xml:base="{replace($xml-base-modified, 'document\.xml', 'comments.xml')}">
        <xsl:apply-templates select="collection()/w:root_converted/w:comments/node()" mode="#current"/>
      </w:comments>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ct:Types" mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:if test="not(Override[@PartName eq '/word/comments.xml'])  and  
                    collection()/w:root_converted/w:comments/node()">
        <Override PartName="/word/comments.xml" xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
          ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>
      </xsl:if>
      <xsl:if test="not(Override[@PartName eq '/word/endnotes.xml'])  and  
                    collection()/w:root_converted/w:endnotes/node()">
        <Override PartName="/word/endnotes.xml" xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
          ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="w:root_converted/w:document/w:body" mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:apply-templates select="collection()/w:root/w:document/w:body/w:sectPr" mode="#current"/>
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
    match=" w:root_converted//w:footnote/@w:id
          | w:root_converted//w:footnoteReference/@w:id
          | w:root_converted//w:bookmarkEnd[
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
    match="w:root_converted//w:bookmarkStart[
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


  <!-- comment chages/additions -->

  <xsl:template match="w:comments" mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="hub:merge" />
      <xsl:apply-templates select="collection()/w:root_converted/w:comments/node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="  w:root_converted//w:comment/@w:id
           | w:root_converted//w:commentReference/@w:id">
    <xsl:param name="commentIdOffset" tunnel="yes" />
    <xsl:attribute name="w:id" select=". + $commentIdOffset"/>
  </xsl:template>


  <!-- relationship changes/additions -->

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//w:hyperlink/@r:id | //w:root_converted//v:imagedata/@r:id">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:attribute name="r:id" select="concat('rId', $relationIdOffset + .)"/>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="rel:Relationships[ends-with(@xml:base, 'document.xml.rels')]">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:apply-templates select="collection()/w:root_converted/w:docRels/rel:Relationships[ends-with(@xml:base, 'document.xml.rels')]/*" mode="#current"/>
      <xsl:if test="not(collection()/w:root/w:comments)">
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
          Id="rId0" 
          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" 
          Target="comments.xml" />
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//rel:Relationship/@Id">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:attribute name="Id" select="concat('rId', $relationIdOffset + . )"/>
  </xsl:template>


  <!-- paragraph changes/additions -->

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//w:pStyle[@hub:val]">
    <xsl:choose> 
      <xsl:when test="@hub:val = collection()//w:styles/w:style[@w:type eq 'paragraph']/@w:styleId">
      <w:pStyle w:val="{@hub:val}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message  select="concat( '&#xa;&#x9;Warning: unexpected role attribute value &quot;', @role, '&quot; for element ', name())"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- character changes/additions -->


  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//w:rStyle[@hub:val]">
    <xsl:choose>
      <xsl:when test="@hub:val = collection()//w:styles/w:style[@w:type eq 'character']/@w:styleId">
        <w:rStyle w:val="{@hub:val}"/>
        <!-- do we have to check for already given properties in existingstyle? -->
        <xsl:apply-templates select="../hub:deviations/node()" mode="#current"/>
      </xsl:when>
      <xsl:when test="../hub:deviations[node()] or ../hub:styles[node()]">
        <xsl:variable name="deviations" as="element()*"
          select="../hub:deviations/node()"/>
        <xsl:apply-templates mode="#current"
          select="../hub:styles/node()[
                    not(
                      name() = (
                        for $i 
                        in $deviations
                        return name($i)
                      )
                    )
                  ], $deviations" />
      </xsl:when>
      <xsl:otherwise>
<!--        <xsl:message  select="concat( '&#xa;&#x9;Warning: unexpected role attribute value &quot;', @role, '&quot; for element ', name(), text: ', substring(string-join(ancestor::w:r[1]//w:t/text(), ''), 10) )"/>-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="//w:root_converted//w:rPr/hub:deviations" mode="hub:merge" />
  <xsl:template match="//w:root_converted//w:rPr/hub:styles" mode="hub:merge" />


  <!-- image changes/additions -->

  <xsl:template match="@hub:fileref" mode="hub:merge">
    <xsl:variable name="rel-element" as="element(rel:Relationship)?"
      select="collection()/w:root/w:docRels//rel:Relationships[ends-with(@xml:base, 'document.xml.rels')]/rel:Relationship[@Target eq current()]"/>
    <xsl:variable name="rel-converted-element" as="element(rel:Relationship)?"
      select="collection()/w:root_converted/w:docRels//rel:Relationships[ends-with(@xml:base, 'document.xml.rels')]/rel:Relationship[@Target eq current()][1]"/>
    <xsl:variable name="relationIdOffset" select="max( for $rId in ( collection()/w:root/w:docRels//rel:Relationships[ends-with(@xml:base, 'document.xml.rels')]/rel:Relationship/@Id ) return number( substring( $rId, 4)))"/>
    <xsl:choose>
      <xsl:when test="$rel-element">
        <xsl:attribute name="r:id" select="$rel-element/@Id"/>
      </xsl:when>
      <xsl:when test="$rel-converted-element">
        <xsl:attribute name="r:id" select="concat('rId', $relationIdOffset + $rel-converted-element/@Id )"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message select="'Warning: Relationship for image', xs:string(.), 'could not be found in template. Image can not be displayed!'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- catch all -->

  <xsl:template 
    match="* | @*" 
    mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

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
  xmlns:letex = "http://www.le-tex.de/namespace"
  xmlns:dbk = "http://docbook.org/ns/docbook"
  xmlns:v             = "urn:schemas-microsoft-com:vml"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  xmlns:customProps = "http://schemas.openxmlformats.org/officeDocument/2006/custom-properties"
  
  xpath-default-namespace = "http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs docx2hub hub hub2docx letex dbk"
  version="2.0">

  <!-- mode merge:
       collection()/w:root_converted: converted hub (see mode hub:default)
       collection()/w:root: docx template w:root
  -->

  <!-- "initial" template:
       apply nodes of docx template in mode hub:merge
  -->
  <xsl:template match="/*" mode="hub:merge">
    <xsl:variable name="document-xml-base-modified" as="attribute(xml:base)">
      <xsl:apply-templates select="/*/w:document/@xml:base" mode="docx2hub:modify"/>
    </xsl:variable>
    <w:root>
      <xsl:apply-templates select="collection()/w:root/*" mode="#current">
        <xsl:with-param name="document-xml-base-modified" tunnel="yes"
          select="$document-xml-base-modified" />
        <xsl:with-param name="footnoteIdOffset" tunnel="yes"
          select="(xs:integer(max(collection()/w:root/w:footnotes/w:footnote/@w:id)), 0)[1]" />
        <xsl:with-param name="commentIdOffset" tunnel="yes"
          select="(xs:integer(max(collection()/w:root/w:comments/w:comment/@w:id)), 0)[1]" />
        <xsl:with-param name="relationIdOffset" tunnel="yes"
          select="max( for $rId in collection()/w:root/w:docRels/rel:Relationships/rel:Relationship/@Id
                       return number( substring( $rId, 4))
                  )" />
        <xsl:with-param name="headerIdOffset" tunnel="yes"
          select="max( (0, for $i in collection()/w:root/w:header/w:hdr/@xml:base 
                       return number(replace(tokenize($i, '/')[last()], '^header(\d+)\.xml$', '$1')))
                  )"/>
        <xsl:with-param name="footerIdOffset" tunnel="yes"
          select="max( (0, for $i in collection()/w:root/w:footer/w:ftr/@xml:base 
                       return number(replace(tokenize($i, '/')[last()], '^footer(\d+)\.xml$', '$1')))
                  )"/>
      </xsl:apply-templates>
    </w:root>
  </xsl:template>

  <xsl:template match="w:document" mode="hub:merge">
    <xsl:param name="document-xml-base-modified" tunnel="yes"/>
    <!-- Works ok with Word 2010. If other apps fail to open the .docx, you might try
    removing copy-nammespaces="no" -->
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="$document-xml-base-modified, collection()/w:root_converted/w:document/node()" mode="#current"/>
    </xsl:copy>

    <!-- no footnotes in template: create the footnote root element separately for converted hub footnotes -->
    <xsl:if test="not(../w:footnotes)  and 
                  collection()/w:root_converted/w:footnotes/node()">
      <w:footnotes xml:base="{replace($document-xml-base-modified, 'document\.xml', 'footnotes.xml')}">
        <xsl:apply-templates select="collection()/w:root_converted/w:footnotes/node()" mode="#current"/>
      </w:footnotes>
    </xsl:if>
    <xsl:if test="not(../w:comments)  and
                  collection()/w:root_converted/w:comments/node()">
      <w:comments xml:base="{replace($document-xml-base-modified, 'document\.xml', 'comments.xml')}">
        <xsl:apply-templates select="collection()/w:root_converted/w:comments/node()" mode="#current"/>
      </w:comments>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ct:Types" mode="hub:merge">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:param name="headerIdOffset" tunnel="yes" />
    <xsl:param name="footerIdOffset" tunnel="yes" />
    <xsl:variable name="Overrides" as="element(ct:Override)*" select="ct:Override"/>
    <xsl:copy>
      <xsl:apply-templates  mode="#current"
        select="@*, *[not(@ContentType = 'application/vnd.openxmlformats-officedocument.custom-properties+xml')]"/>
      <xsl:if test="not(ct:Override[@PartName eq '/word/comments.xml'])  and  
                    collection()/w:root_converted/w:comments/node()">
        <Override PartName="/word/comments.xml" xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
          ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>
      </xsl:if>
      <xsl:if test="not(ct:Override[@PartName eq '/word/endnotes.xml'])  and  
                    collection()/w:root_converted/w:endnotes/node()">
        <Override PartName="/word/endnotes.xml" xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
          ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.endnotes+xml"/>
      </xsl:if>
      <xsl:for-each select="collection()/w:root_converted/*/w:hdr">
        <xsl:variable name="number" select="$headerIdOffset + @hub:offset"/>
        <xsl:if test="not($Overrides[@PartName eq concat('/word/header',$number,'.xml')])">
          <Override xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
            PartName="/word/header{$number}.xml"
            ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="collection()/w:root_converted/*/w:ftr">
        <xsl:variable name="number" select="$footerIdOffset + @hub:offset"/>
        <xsl:if test="not($Overrides[@PartName eq concat('/word/footer',$number,'.xml')])">
          <Override xmlns="http://schemas.openxmlformats.org/package/2006/content-types"
            PartName="/word/footer{$number}.xml"
            ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:if test="collection()/w:root_converted/w:containerProps/customProps:Properties/customProps:property">
        <Override xmlns="http://schemas.openxmlformats.org/package/2006/content-types" 
          PartName="/docProps/custom.xml"
          ContentType="application/vnd.openxmlformats-officedocument.custom-properties+xml"/>
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
  
  <xsl:template match="w:settings" mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, * except w:docVars" mode="#current"/>
      <w:docVars>
        <xsl:sequence select="collection()/w:root_converted/w:settings/w:docVars/w:docVar"/>
      </w:docVars>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="  w:root_converted//w:comment/@w:id
           | w:root_converted//w:commentReference/@w:id">
    <xsl:param name="commentIdOffset" tunnel="yes" />
    <xsl:attribute name="w:id" select=". + $commentIdOffset"/>
  </xsl:template>

  <!-- container relationship (_rels/.rels) changes/additions -->
  
  <xsl:template mode="hub:merge" match="w:containerRels/rel:Relationships">
    <xsl:variable name="other-rels" as="element(rel:Relationship)+"
      select="*[not(@Type = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships/custom-properties')]"/>
    <xsl:variable name="rid" as="xs:double" select="max(for $i in $other-rels/@Id return number(substring($i, 4))) + 1"/>
    <xsl:copy>
      <xsl:apply-templates  mode="#current"
        select="@*, $other-rels"/>
      <xsl:if test="collection()/w:root_converted/w:containerProps/customProps:Properties/customProps:property">
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships" 
          Id="rId{$rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/custom-properties" Target="docProps/custom.xml"/>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="hub:merge" match="w:containerProps">
    <xsl:copy>
      <xsl:apply-templates  mode="#current" select="* except customProps:Properties"/>
      <xsl:if test="collection()/w:root_converted/w:containerProps/customProps:Properties/customProps:property">
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/custom-properties">
          <xsl:if test="*[1]/@xml:base">
            <xsl:variable name="prelim" as="attribute(xml:base)">
              <xsl:attribute name="xml:base" select="replace(*[1]/@xml:base, '[^/]+$', 'custom.xml')"/>  
            </xsl:variable>
            <xsl:apply-templates select="$prelim" mode="docx2hub:modify"/><!-- out dir -->
          </xsl:if>
          <xsl:apply-templates  mode="#current"
            select="collection()/w:root_converted/w:containerProps/customProps:Properties/customProps:property"/>
        </Properties>
      </xsl:if>
    </xsl:copy>
  </xsl:template>
    
  <xsl:template match="customProps:property" mode="hub:merge">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="pid" select="position() + 1"/><!-- has to start with 2, for whatever reason -->
      <xsl:apply-templates select="*" mode="#current"/>
    </xsl:copy>
    
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
    match="w:docRels/rel:Relationships">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:param name="headerIdOffset" tunnel="yes" />
    <xsl:param name="footerIdOffset" tunnel="yes" />
    <xsl:copy>
      <xsl:apply-templates  mode="#current"
        select="@*, *[not(@Target = collection()/w:root_converted/w:docRels/rel:Relationships/*/@Target)]"/>
      <xsl:apply-templates select="collection()/w:root_converted/w:docRels/rel:Relationships/*" mode="#current"/>
      <xsl:if test="not(collection()/w:root/w:comments) and
                    collection()/w:root_converted/w:comments/node()">
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
          Id="rId{$relationIdOffset}c" 
          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments" 
          Target="comments.xml" />
      </xsl:if>
      <xsl:for-each select="collection()/w:root_converted/*/w:*[local-name() = ('ftr', 'hdr')]">
        <xsl:variable name="type" select="if(local-name() eq 'ftr') then 'footer' else 'header'" as="xs:string"/>
        <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
          Id="rId{$relationIdOffset + @hub:offset}{local-name()}" 
          Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/{$type}" 
          Target="{$type}{(if(local-name() eq 'ftr') then $footerIdOffset else $headerIdOffset) + @hub:offset}.xml" />
      </xsl:for-each>
    </xsl:copy>
  </xsl:template>

  <!-- insert relationships for newly created header or footer content -->
  <xsl:template 
    mode="hub:merge"
    match="  w:headerRels
           | w:footerRels">
    <xsl:param name="headerIdOffset" tunnel="yes"/>
    <xsl:param name="footerIdOffset" tunnel="yes"/>
    <xsl:param name="document-xml-base-modified" tunnel="yes"/>

    <xsl:variable name="ref-name-long" as="xs:string"
      select="if(name() eq 'w:headerRels') then 'header' else 'footer'"/>
    <xsl:variable name="offset" as="xs:double"
      select="if($ref-name-long eq 'header') then $headerIdOffset else $footerIdOffset"/>

    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <xsl:if test="collection()/w:root_converted/w:*[local-name() eq $ref-name-long]/w:*//@hub:fileref">
        <xsl:for-each select="collection()/w:root_converted/w:*[local-name() eq $ref-name-long]/w:*[.//@hub:fileref]">
          <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
            <xsl:attribute name="xml:base" 
              select="replace(
                        letex:get-new-xml-base(., $offset, $document-xml-base-modified), 
                        concat('/(', $ref-name-long, '\d+\.xml)'), 
                        '/_rels/$1.rels'
                      )"/>
            <xsl:for-each select="collection()/w:root_converted/w:*[local-name() eq $ref-name-long]/w:*//@hub:fileref">
              <Relationship xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
                Id="rId{../@id}{local-name(ancestor::w:*[local-name() = ('hdr', 'ftr')])}" 
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" 
                Target="{current()}" />
            </xsl:for-each>
          </Relationships>
        </xsl:for-each>
      </xsl:if>
    </xsl:copy>
  </xsl:template>

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//rel:Relationship/@Id">
    <xsl:param name="relationIdOffset" tunnel="yes" />
    <xsl:attribute name="Id" select="concat('rId', $relationIdOffset + . )"/>
  </xsl:template>


  <!-- header and footer changes/additions -->

  <xsl:template match="w:header" mode="hub:merge">
    <xsl:apply-templates mode="#current"/>
    <xsl:apply-templates select="collection()/w:root_converted/w:header/w:hdr" mode="#current" />
  </xsl:template>

  <xsl:template match="w:footer" mode="hub:merge">
    <xsl:apply-templates mode="#current"/>
    <xsl:apply-templates select="collection()/w:root_converted/w:footer/w:ftr" mode="#current" />
  </xsl:template>

  <xsl:function name="letex:get-new-xml-base" as="xs:string">
    <xsl:param name="current-node" as="element()"/>
    <xsl:param name="typeIdOffset" as="xs:double"/>
    <xsl:param name="document-xml-base-modified" as="xs:string"/>
    <xsl:variable name="type" as="xs:string">
      <xsl:choose>
        <xsl:when test="local-name($current-node) eq 'hdr'">
          <xsl:value-of select="'header'"/>
        </xsl:when>
        <xsl:when test="local-name($current-node) eq 'ftr'">
          <xsl:value-of select="'footer'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message select="'Warning, function letex:get-new-xml-base: unkown element name: ', local-name($current-node)"/>
          <xsl:value-of select="local-name($current-node)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="replace(
                            $document-xml-base-modified, 
                            'document\.xml', 
                            concat($type, $typeIdOffset + $current-node/@hub:offset, '.xml')
                          )"/>
  </xsl:function>

  <xsl:template match="/w:root_converted/w:header/w:hdr" mode="hub:merge">
    <xsl:param name="headerIdOffset" tunnel="yes"/>
    <xsl:param name="document-xml-base-modified" tunnel="yes"/>
    <xsl:copy>
      <xsl:attribute name="xml:base" 
        select="letex:get-new-xml-base(., $headerIdOffset, $document-xml-base-modified)"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="/w:root_converted/w:footer/w:ftr" mode="hub:merge">
    <xsl:param name="footerIdOffset" tunnel="yes"/>
    <xsl:param name="document-xml-base-modified" tunnel="yes"/>
    <xsl:copy>
      <xsl:attribute name="xml:base" 
        select="letex:get-new-xml-base(., $footerIdOffset, $document-xml-base-modified)"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- set header and footer references
       generated output will look like:
       <w:footerReference w:type="default" r:id="rId15ftr"/>
       <w:headerReference w:type="first" r:id="rId15hdr"/> -->
  <xsl:template mode="hub:merge"
    match="  /w:root/w:document/w:body/w:sectPr/w:headerReference/@r:id
           | /w:root/w:document/w:body/w:sectPr/w:footerReference/@r:id">
    <xsl:param name="relationIdOffset" tunnel="yes"/>

    <xsl:variable name="ref-name-short" as="xs:string"
      select="if(name(..) eq 'w:headerReference') then 'hdr' else 'ftr'"/>
    <xsl:variable name="ref-name-long" as="xs:string"
      select="if($ref-name-short eq 'hdr') then 'header' else 'footer'"/>
    <xsl:variable name="corresponding-converted-margin-element" as="element(*)?"
      select="collection()/w:root_converted
                /w:*[local-name() eq $ref-name-long]
                  /w:*[local-name() eq $ref-name-short][
                    @hub:*[
                      matches(
                        local-name(.),
                        concat(
                          '^',
                          $ref-name-long,
                          '-', 
                          current()/../@w:type, 
                          '$'
                        )
                      )
                    ]
                  ]"/>

    <xsl:attribute name="r:id">
      <xsl:choose>
        <xsl:when test="$corresponding-converted-margin-element">
          <xsl:value-of select="concat('rId', $corresponding-converted-margin-element[last()]/@hub:offset + $relationIdOffset, $ref-name-short)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>


  <!-- paragraph changes/additions -->

  <xsl:variable name="word-builtin-pStyles" as="xs:string+"
    select="('Fußzeile', 'Kopfzeile', 'Header')"/>

  <xsl:template 
    mode="hub:merge"
    match="//w:root_converted//w:pStyle[@hub:val]">
    <xsl:choose>
      <xsl:when test="@hub:val = collection()//w:styles/w:style[@w:type eq 'paragraph']/@w:styleId or @hub:val = $word-builtin-pStyles">
        <w:pStyle w:val="{@hub:val}"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message  select="concat( '&#xa;&#x9;Warning: unexpected role attribute value &quot;', @hub:val, '&quot; for element ', name(), ' (not in template).')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- character changes/additions -->

  <xsl:template match="w:rStyle/@hub:val[. = collection()//w:styles/w:style[@w:type eq 'character']/@w:styleId]">
    <xsl:attribute name="w:val" select="."/>
  </xsl:template>

  <xsl:template match="//w:root_converted//w:rPr/hub:styles" mode="hub:merge" />


  <!-- image changes/additions -->

  <xsl:template match="@hub:fileref" mode="hub:merge">
    <xsl:param name="relationIdOffset" tunnel="yes"/>
    <xsl:variable name="rel-element" as="element(rel:Relationship)?"
      select="collection()/w:root
                /w:*[local-name() = ('docRels', 'headerRels', 'footerRels')]
                  /rel:Relationships/rel:Relationship[@Target eq current()]"/>
    <xsl:variable name="rel-converted-element" as="element(rel:Relationship)?"
      select="collection()/w:root_converted
                /w:*[local-name() = ('docRels', 'headerRels', 'footerRels')]
                  /rel:Relationships/rel:Relationship[@Target eq current()][1]"/>
    <xsl:choose>
      <!-- referenced file will be placed in a header or footer -->
      <xsl:when test="$rel-element and (ancestor::w:hdr or ancestor::w:ftr)">
        <xsl:attribute name="r:id" select="concat('rId', ../@id, local-name(ancestor::w:*[local-name() = ('hdr', 'ftr')]))"/>
      </xsl:when>
      <!-- found referenced file in template -->
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

  <xsl:template match="v:imagedata[@hub:fileref]/@id" mode="hub:merge" />

  <!-- catch all -->

  <xsl:template 
    match="* | @*" 
    mode="hub:merge">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current" />
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>

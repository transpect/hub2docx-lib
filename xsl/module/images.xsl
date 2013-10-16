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
    xmlns:css           = "http://www.w3.org/1996/css"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:r             = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:v             = "urn:schemas-microsoft-com:vml"
    xmlns:w10="urn:schemas-microsoft-com:office:word"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon letex saxExtFn hub xlink o w m rel wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="informalfigure | figure" mode="hub:default">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

  <xsl:template match="mediaobject[not(parent::para)]" mode="hub:default">
    <w:p>
      <xsl:variable name="pictstyle" as="xs:string*">
        <xsl:if test="@annotation='anchor'">
          <xsl:value-of select="'position:absolute;z-index:-1'"/>
        </xsl:if>
        <xsl:for-each select="@css:margin-left|@css:margin-top|descendant-or-self::*/@css:width|descendant-or-self::*/@css:height">
          <xsl:value-of select="concat(local-name(.),':',.)"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:choose>
        <xsl:when test="count(.//imagedata) eq 1 and
          matches(.//imagedata/@fileref, '^container[:]')">
          <w:r>
            <w:pict>
              <v:shape id="h2d_img{index-of($MediaIds, generate-id(.))}" style="{string-join($pictstyle,';')}">
                <v:imagedata hub:fileref="{replace(.//@fileref, '^container[:]', '')}" o:title=""/>
                <xsl:if test="@annotation='anchor'">
                  <w10:anchorlock/>
                </xsl:if>
              </v:shape>
            </w:pict>
          </w:r>
        </xsl:when>
        <xsl:otherwise>
          <w:r>
            <w:pict>
              <v:shape id="h2d_img{index-of($MediaIds, generate-id(.))}" style="{string-join($pictstyle,';')}">
                <v:imagedata hub:fileref="{.//@fileref}" o:title="" r:id="{index-of($rels, generate-id(.))}"/>
                <xsl:if test="@annotation='anchor'">
                  <w10:anchorlock/>
                </xsl:if>
              </v:shape>
            </w:pict>
          </w:r>
        </xsl:otherwise>
      </xsl:choose>
    </w:p>
  </xsl:template>

  <xsl:variable name="MediaIds" as="xs:string*"
    select="for $f 
            in //*[local-name() = ('mediaobject', 'inlinemediaobject')] 
            return generate-id($f)" />

  <xsl:template match="inlinemediaobject | para/mediaobject" mode="hub:default">
    <xsl:variable name="pictstyle" as="xs:string*">
      <xsl:if test="@annotation='anchor'">
        <xsl:value-of select="'position:absolute;z-index:-1'"/>
      </xsl:if>
      <xsl:for-each select="@css:margin-left|@css:margin-top|descendant-or-self::*/@css:width|descendant-or-self::*/@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="count(.//imagedata) eq 1 and
                      matches(.//imagedata/@fileref, '^container[:]')">
        <w:r>
          <w:pict>
            <v:shape id="h2d_img{index-of($MediaIds, generate-id(.))}" style="{string-join($pictstyle,';')}">
              <v:imagedata hub:fileref="{replace(.//@fileref, '^container[:]', '')}" id="img{index-of($MediaIds, generate-id(.))}" o:title=""/>
              <xsl:if test="@annotation='anchor'">
                <w10:anchorlock/>
              </xsl:if>
            </v:shape>
          </w:pict>
        </w:r>
      </xsl:when>
      <xsl:otherwise>
        <w:r>
          <w:pict>
            <v:shape id="h2d_img{index-of($MediaIds, generate-id(.))}" style="{string-join($pictstyle,';')}">
              <v:imagedata hub:fileref="{.//@fileref}" o:title="" r:id="{index-of($rels, generate-id(.))}"/>
              <xsl:if test="@annotation='anchor'">
                <w10:anchorlock/>
              </xsl:if>
            </v:shape>
          </w:pict>
        </w:r>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="sidebar[parent::para]" mode="hub:default">
    <xsl:variable name="sidebar-style" as="xs:string*">
      <xsl:value-of select="'position:absolute;z-index:1'"/>
      <xsl:for-each select="@css:margin-left|@css:margin-top|descendant-or-self::*/@css:width|descendant-or-self::*/@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="inset" as="xs:string" select="concat(if (exists(@css:padding-left)) then @css:padding-left else '0.1in',',',if (exists(@css:padding-top)) then @css:padding-top else '0.05in',',',if (exists(@css:padding-right)) then @css:padding-right else '0.1in',',',if (exists(@css:padding-bottom)) then @css:padding-bottom else '0.05in')"/>
    <w:r>
      <w:pict>
        <v:shape coordsize="21600,21600" path="m,l,21600r21600,l21600,xe" o:spt="100">
          <xsl:attribute name="style" select="string-join($sidebar-style,';')"/>
          <v:textbox>
            <xsl:attribute name="inset" select="$inset"/>
            <w:txbxContent>
              <xsl:apply-templates mode="#current"/>
            </w:txbxContent>
          </v:textbox>
        </v:shape>
      </w:pict>
    </w:r>
  </xsl:template>
  
  <xsl:template match="sidebar[not(parent::para)]" mode="hub:default">
    <xsl:variable name="sidebar-style" as="xs:string*">
      <xsl:value-of select="'position:absolute;z-index:1'"/>
      <xsl:for-each select="@css:margin-left|@css:margin-top">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="inset" as="xs:string" select="concat(if (exists(@css:padding-left)) then @css:padding-left else '0.1in',',',if (exists(@css:padding-top)) then @css:padding-top else '0.05in',',',if (exists(@css:padding-right)) then @css:padding-right else '0.1in',',',if (exists(@css:padding-bottom)) then @css:padding-bottom else '0.05in')"/>
    <w:p>
      <xsl:if test="exists(para[@role]) and (every $i in (para/@role) satisfies $i eq (para/@role)[1])">
        <w:pPr>
          <w:pStyle w:val="{(para/@role)[1]}"/>
        </w:pPr>
      </xsl:if>
      <w:r>
        <w:pict>
          <v:shape coordsize="21600,21600" o:spt="202"
            path="m,l,21600r21600,l21600,xe">
            <xsl:attribute name="style" select="string-join($sidebar-style,';')"/>
            <v:textbox>
              <xsl:attribute name="inset" select="$inset"/>
              <w:txbxContent>
                <xsl:apply-templates mode="#current"/>
              </w:txbxContent>
            </v:textbox>
          </v:shape>
        </w:pict>
      </w:r>
    </w:p>
  </xsl:template>
  
  <xsl:template match="figure/title" mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="FigureTitle"/>
      </w:pPr>
      <xsl:apply-templates mode="#current"/>
    </w:p>
  </xsl:template>

  <xsl:template  match="mediaobject"  mode="hub:default-DISABLED">
    <w:p>
      <w:r>
        <w:rPr>
          <w:noProof/>
        </w:rPr>
        <w:drawing>
          <wp:inline distT="0" distB="0" distL="0" distR="0"> -->
<!--             <wp:extent cx="2682473" cy="2194750"/> -->
<!--             <wp:effectExtent l="19050" t="0" r="3577" b="0"/> -->
<!--             <wp:docPr id="1" name="Grafik 0" descr="Abbildung 1.png"/> -->
<!--             <wp:cNvGraphicFramePr> -->
<!--               <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/> -->
<!--             </wp:cNvGraphicFramePr> -->
            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
<!--                 <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"> -->
<!--                   <pic:nvPicPr> -->
<!--                     <pic:cNvPr id="0" name="Abbildung 1.png"/> -->
<!--                     <pic:cNvPicPr/> -->
<!--                   </pic:nvPicPr> -->
<!--                   <pic:blipFill> -->
<!--                     <a:blip r:embed="rId8"/> -->
<!--                     <a:stretch> -->
<!--                       <a:fillRect/> -->
<!--                     </a:stretch> -->
<!--                   </pic:blipFill> -->
<!--                   <pic:spPr> -->
<!--                     <a:xfrm> -->
<!--                       <a:off x="0" y="0"/> -->
<!--                       <a:ext cx="2682473" cy="2194750"/> -->
<!--                     </a:xfrm> -->
<!--                     <a:prstGeom prst="rect"> -->
<!--                       <a:avLst/> -->
<!--                     </a:prstGeom> -->
<!--                   </pic:spPr> -->
<!--                 </pic:pic> -->
              </a:graphicData>
            </a:graphic>
          </wp:inline>
        </w:drawing>
      </w:r>
    </w:p>
  </xsl:template>

  <!--  mode = "documentRels"-->
  
  <xsl:template  match="inlinemediaobject[not(count(.//imagedata) eq 1 and matches(.//imagedata/@fileref, '^container[:]'))] | 
                        mediaobject[not(count(.//imagedata) eq 1 and matches(.//imagedata/@fileref, '^container[:]'))]"  
                 mode="documentRels">
    <Relationship Id="{index-of($rels, generate-id(.))}"  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"  Target="{.//@fileref}" xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
  </xsl:template>

</xsl:stylesheet>

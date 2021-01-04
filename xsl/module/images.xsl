<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:docx2hub      = "http://transpect.io/docx2hub"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:r             = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:v             = "urn:schemas-microsoft-com:vml"
    xmlns:w10="urn:schemas-microsoft-com:office:word"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink o w m rel wp r css docx2hub w10 hub"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="informalfigure | figure" mode="hub:default">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>
  
  <xsl:template match="alternatives" mode="hub:default"/>
 
  <xsl:variable name="MediaIds" as="xs:string*"
    select="for $f 
            in //*[local-name() = ('mediaobject', 'inlinemediaobject')][./imageobject/imagedata/@fileref != ''] 
            return generate-id($f)" />

  <xsl:template match="mediaobject[not(ancestor::para) and not(parent::term)]" mode="hub:default">
    <w:p origin="default_i_mediaonotparentp">
      <xsl:variable name="pPr">
        <xsl:apply-templates select="@css:text-align | @css:page-break-before" mode="props"/>
      </xsl:variable>
      <xsl:if test="$pPr">
        <w:pPr>
          <xsl:sequence select="$pPr"/>
        </w:pPr>
      </xsl:if>
      <xsl:call-template name="insert-picture"/>
    </w:p>
    <xsl:apply-templates select="caption" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="mediaobject/caption" mode="hub:default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="inlinemediaobject | mediaobject[ancestor::para or parent::term]" mode="hub:default" name="insert-picture">
    <xsl:param name="rels" as="xs:string*" tunnel="yes"/>
    <xsl:variable name="pictstyle" as="xs:string*">
      <xsl:for-each select="@css:position|@css:margin-left|@css:margin-top|@css:z-index|descendant-or-self::*/@css:width|descendant-or-self::*/@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="media-id" select="index-of($MediaIds, generate-id(.))" as="xs:integer"/>
    <xsl:choose>
      <xsl:when test="count(./imageobject/imagedata) eq 1 and
                      matches(./imageobject/imagedata/@fileref, '^container[:]')">
        <w:r>
          <w:pict>
            <v:shape id="h2d_img{$media-id}" style="{string-join($pictstyle,';')}">
              <xsl:call-template name="v:shape-border-atts"/>
              <v:imagedata hub:fileref="{replace(./imageobject[1]/imagedata/@fileref, '^container:word/', '')}" 
                r:id="{index-of($rels, generate-id(.))}" id="img{$media-id}" o:title=""/>
              <xsl:if test="@annotation='anchor'">
                <w10:anchorlock/>
              </xsl:if>
              <xsl:call-template name="v:shape-border-elts"/>
            </v:shape>
          </w:pict>
        </w:r>
      </xsl:when>
      <xsl:otherwise>
        <w:r>
          <w:pict>
            <v:shape id="h2d_img{$media-id}" style="{string-join($pictstyle,';')}">
              <xsl:call-template name="v:shape-border-atts"/>
              <v:imagedata hub:fileref="{./imageobject/imagedata/@fileref}" o:title="" 
                r:id="{index-of($rels, generate-id(.))}" id="img{$media-id}"/>
              <xsl:if test="@annotation='anchor'">
                <w10:anchorlock/>
              </xsl:if>
              <xsl:call-template name="v:shape-border-elts"/>
            </v:shape>
          </w:pict>
        </w:r>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="v:shape-border-atts">
    <xsl:for-each select="@css:*[matches(local-name(), '^border-.+-color')]">
      <xsl:attribute name="o:{replace(local-name(), '-', '')}" select="tr:convert-css-color(., 'hex')"/>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template name="v:shape-border-elts">
    <xsl:if test="exists(@css:*[starts-with(local-name(), 'border-')])">
      <v:stroke joinstyle="miter"/>
      <v:path o:connecttype="segments"/>
    </xsl:if>
    <xsl:for-each select="@css:*[matches(local-name(), '^border-.+-width')]">
      <xsl:variable name="side" as="xs:string" select="replace(local-name(), 'border-(.+)-width', '$1')"/>
      <xsl:element name="w10:border{$side}">
        <xsl:apply-templates select="., ../@css:*[local-name() = concat('border-', $side, '-style')]" mode="v:shape-border"/>
      </xsl:element>
    </xsl:for-each>
  </xsl:template>
  
  <xsl:template match="@css:*[matches(local-name(), '^border-.+-width$')]" mode="v:shape-border">
    <xsl:attribute name="width">
      <xsl:choose>
        <xsl:when test=". = 'thick'">
          <xsl:sequence select="32"/>
        </xsl:when>
        <xsl:when test=". = 'medium'">
          <xsl:sequence select="8"/>
        </xsl:when>
        <xsl:when test=". = 'thin'">
          <xsl:sequence select="4"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="xs:integer(tr:length-to-unitless-twip(.) * 0.4)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@css:*[matches(local-name(), '^border-.+-style$')]" mode="v:shape-border">
    <xsl:attribute name="type" select="tr:border-style(.)"/>
  </xsl:template>
  
  <xsl:template match="sidebar[parent::para or parent::title]" mode="hub:default">
    <xsl:variable name="sidebar-style" as="xs:string*">
      <xsl:for-each select="@css:position|@css:z-index|@css:margin-left|@css:margin-top|descendant-or-self::*[not(self::imagedata)]/@css:width|descendant-or-self::*[not(self::imagedata)]/@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
      <xsl:if test="not(descendant-or-self::*/@css:width)">
        <xsl:value-of select="'mso-width-percent:1000;mso-width-relative:margin'"/>
      </xsl:if>
      <xsl:if test="not(descendant-or-self::*/@css:height)">
        <xsl:value-of select="'mso-height-percent:250;mso-height-relative:margin-bottom'"/>
      </xsl:if>
      <xsl:if test="not(descendant-or-self::*[not(self::imagedata)]/@css:width or descendant-or-self::*[not(self::imagedata)]/@css:height)">
        <xsl:value-of select="'mso-wrap-style:none'"/>  
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="inset" as="xs:string" select="concat(if (exists(@css:padding-left)) then @css:padding-left else '0.1in',',',if (exists(@css:padding-top)) then @css:padding-top else '0.05in',',',if (exists(@css:padding-right)) then @css:padding-right else '0.1in',',',if (exists(@css:padding-bottom)) then @css:padding-bottom else '0.05in')"/>
    <w:r>
      <w:pict>
        <v:shape coordsize="21600,21600" path="m,l,21600r21600,l21600,xe" o:spt="100">
          <xsl:attribute name="style" select="string-join($sidebar-style,';')"/>
          <xsl:if test="@css:background-color ne ''">
            <xsl:attribute name="fillcolor" select="tr:convert-css-color(@css:background-color, 'hex')"/>
          </xsl:if>
          <xsl:if test="@css:border-style = 'none'">
            <xsl:attribute name="stroked" select="'false'"/>
          </xsl:if>
          <xsl:if test="@css:border-color">
            <xsl:attribute name="strokecolor" select="@css:border-color"/>
          </xsl:if>
          <xsl:if test="@css:border-width">
            <xsl:attribute name="strokeweight" select="@css:border-width"/>
          </xsl:if>
          <xsl:attribute name="o:allowoverlap" select="'f'"/>
          <v:textbox>
            <xsl:attribute name="inset" select="$inset"/>
            <xsl:if test="not(descendant-or-self::*[not(self::imagedata)]/@css:width or descendant-or-self::*[not(self::imagedata)]/@css:height)">
              <xsl:attribute name="style" select="'mso-fit-shape-to-text:t'"/>
            </xsl:if>
            <w:txbxContent>
              <xsl:apply-templates mode="#current"/>
            </w:txbxContent>
          </v:textbox>
          <xsl:if test="@css:display='block'">
            <w10:wrap type="topAndBottom"/>  
          </xsl:if>
        </v:shape>
      </w:pict>
    </w:r>
  </xsl:template>
  
  <xsl:template match="sidebar[not(parent::para or parent::title)]" mode="hub:default">
    <xsl:variable name="sidebar-style" as="xs:string*">
      <xsl:for-each select="@css:position|@css:z-index|@css:margin-left|@css:margin-top|@css:width|@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="inset" as="xs:string" select="concat(if (exists(@css:padding-left)) then @css:padding-left else '0.1in',',',if (exists(@css:padding-top)) then @css:padding-top else '0.05in',',',if (exists(@css:padding-right)) then @css:padding-right else '0.1in',',',if (exists(@css:padding-bottom)) then @css:padding-bottom else '0.05in')"/>
    <w:p origin="default_i_sidebarnotparpara">
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
            <xsl:if test="@css:background-color ne ''">
              <xsl:attribute name="fillcolor" select="concat('#', tr:convert-css-color(@css:background-color, 'hex'))"/>
            </xsl:if>
            <xsl:if test="@css:border-style = 'none'">
              <xsl:attribute name="stroked" select="'false'"/>
            </xsl:if>
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
  
  <xsl:template match="symbol" mode="hub:default">
    <xsl:variable name="sidebar-style" as="xs:string*">
      <xsl:for-each select="@css:position|@css:z-index|@css:margin-left|@css:margin-top|@css:width|@css:height">
        <xsl:value-of select="concat(local-name(.),':',.)"/>
      </xsl:for-each>
    </xsl:variable>
    <w:r>
      <w:pict>
        <xsl:element name="{.}">
          <xsl:attribute name="coordsize" select="'21600,21600'"/>
          <xsl:attribute name="o:spt" select="'100'"/>
          <xsl:attribute name="style" select="string-join($sidebar-style,';')"/>
          <xsl:if test="@css:background-color ne ''">
            <xsl:attribute name="fillcolor" select="tr:convert-css-color(@css:background-color, 'hex')"/>
          </xsl:if>
        </xsl:element>
      </w:pict>
    </w:r>
  </xsl:template>
  
  <xsl:template match="figure/title" mode="hub:default">
    <xsl:variable name="pPr" as="element(*)*">
      <xsl:apply-templates  select="@css:page-break-after, 
                                    @css:page-break-inside, 
                                    @css:page-break-before, 
                                    @css:text-indent, 
                                    (@css:widows, @css:orphans)[1], 
                                    @css:margin-bottom, 
                                    @css:margin-top, 
                                    @css:line-height, 
                                    @css:text-align"  mode="props" />
      <w:pStyle>
        <xsl:attribute name="w:val" select="if (@role) 
                                            then @role 
                                            else
                                               if ($template-lang = 'en') 
                                               then 'Figuretitle' 
                                               else 'Abbildungslegende'"/>
      </w:pStyle>
    </xsl:variable>
    <w:p origin="default_i_figtitle">
      <xsl:if  test="$pPr">
        <w:pPr>
          <xsl:sequence  select="$pPr" />
        </w:pPr>
      </xsl:if>
      <xsl:apply-templates mode="#current"/>
    </w:p>
  </xsl:template>

  <!--  mode = "documentRels"-->
  
  <xsl:template  match="inlinemediaobject[not(count(./imageobject/imagedata) eq 1 and matches(./imageobject/imagedata/@fileref, '^container[:]'))] | 
                        mediaobject[./imageobject/imagedata/@fileref != ''][not(count(./imageobject/imagedata) eq 1 and matches(./imageobject/imagedata/@fileref, '^container[:]'))]"  
                 mode="documentRels footnoteRels">
    <xsl:param name="rels" as="xs:string+" tunnel="yes"/>
    <Relationship Id="{index-of($rels, generate-id(.))}"  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"  
      Target="{./imageobject[1]/imagedata/@fileref}" xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
      <xsl:if test="not(matches(./imageobject[1]/imagedata/@fileref,'^media'))">
        <xsl:attribute name="TargetMode" select="'External'"/>
      </xsl:if>
    </Relationship>
  </xsl:template>

  <xsl:template  match="*[self::inlinemediaobject | self::mediaobject][starts-with(imageobject[1]/imagedata/@fileref, 'container:')]"  
    mode="documentRels footnoteRels">
    <xsl:param name="rels" as="xs:string+" tunnel="yes"/>
    <Relationship Id="{index-of($rels, generate-id(.))}"  Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"  
      Target="{replace(imageobject[1]/imagedata/@fileref, 'container:word/', '')}" xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>
  </xsl:template>
  
</xsl:stylesheet>

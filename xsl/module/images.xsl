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

  <xsl:template match="informalfigure | figure" mode="hub:default">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

  <xsl:template match="mediaobject[not(parent::para)]" mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="ObjectPlaceholder"/>
      </w:pPr>
      <w:r>
        <w:t>
          MEDIA OBJECT: <xsl:value-of select=".//*/@fileref" />
        </w:t>
      </w:r>
    </w:p>
  </xsl:template>

  <xsl:template match="inlinemediaobject | para/mediaobject" mode="hub:default">
    <w:r>
      <w:t> INLINE MEDIA OBJECT: <xsl:value-of select=".//*/@fileref"/>
      </w:t>
    </w:r>
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


</xsl:stylesheet>

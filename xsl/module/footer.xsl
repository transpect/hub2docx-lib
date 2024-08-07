<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:tr		= "http://transpect.io"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:css           = "http://www.w3.org/1996/css"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:rel		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn css xlink o w m wp r"
>

  <!--
       Input example (set only default footer):
       <hub>
         <info>
           <css:rules>
             <css:page pseudo="right" name="myfooter">
               <css:page-margin-box location="bottom-center"/>
             </css:page>
             <css:rule name="anyfooter" layout-type="object"/>
           </css:rules>
         </info>
         <sidebar role="anyfooter" css:page="myfooter"><para>My Footer</para></sidebar>
  -->

  <xsl:variable name="originalFooterIds" as="xs:string*"
    select="for $h in //*[not(parent::css:page)][@css:page][tr:is-footer(.)] return generate-id($h)" />

  <xsl:function name="tr:footer-id" as="xs:integer">
    <xsl:param name="footer" as="element(sidebar)" />
    <xsl:sequence select="index-of($originalFooterIds, generate-id($footer))" />
  </xsl:function>

  <xsl:template match="*[@css:page][tr:is-footer(.)]" mode="footer">
    <w:ftr hub:offset="{tr:footer-id(.)}">
      <xsl:for-each select="tokenize(/*/info/css:rules/css:page[@name eq current()/@css:page]/@pseudo, '&#x20;')">
        <xsl:choose>
          <xsl:when test=". eq 'first'">
            <xsl:attribute name="hub:footer-first" select="'true'"/>
          </xsl:when>
          <xsl:when test=". eq 'right'">
            <xsl:attribute name="hub:footer-default" select="'true'"/>
          </xsl:when>
          <xsl:when test=". eq 'left'">
            <xsl:attribute name="hub:footer-even" select="'true'"/>
          </xsl:when>
          <xsl:otherwise/>
        </xsl:choose>
      </xsl:for-each>
      <xsl:apply-templates mode="hub:default"/>
    </w:ftr>
  </xsl:template>

  <xsl:template match="phrase[@role='hub:page-number']" mode="hub:default">
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:instrText>PAGE  \* Arabic  \* MERGEFORMAT</w:instrText>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="separate"/>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:t>1</w:t>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="end"/>
    </w:r>  
  </xsl:template>
  
  <xsl:template match="phrase[@role='hub:page-count']" mode="hub:default">
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:instrText>NUMPAGES  \* Arabic  \* MERGEFORMAT</w:instrText>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="separate"/>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:t>1</w:t>
    </w:r>
    <w:r>
      <w:rPr>
        <w:color w:val="auto"/>
        <w:sz w:val="{if (ancestor-or-self::*/@css:font-size) 
                      then round(tr:length-to-unitless-twip(ancestor-or-self::*[@css:font-size][1]/@css:font-size) idiv 10) 
                      else '20'}"/>
      </w:rPr>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>

</xsl:stylesheet>

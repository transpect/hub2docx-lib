<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon saxExtFn hub xlink o w m wp r"
>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <!-- ISO 29500-1, 17.16.5.72, S. 1400 -->

  <!-- use a key to speed up the lookup -->
  <xsl:key name="startofrangeIndexterms"  match="//indexterm[ @class = ( 'startofrange', 'singular' ) ]"  use="@xml:id"/>
    
  <xsl:template  match="indexterm[ @class eq 'endofrange' ]"  mode="hub:default">
    <xsl:variable  name="correspondingStartofrangeIndexterm"  select="key(  'startofrangeIndexterms', @startref)"/>
    <w:bookmarkEnd  w:id="{$correspondingStartofrangeIndexterm/generate-id()}"/>
  </xsl:template>

  <xsl:template  match="indexterm[ not(@class) or @class ne 'endofrange' ]"  mode="hub:default">
    <xsl:param name="see-prefix" 
      select="if(/*/@xml:lang = 'de') then 'Siehe' else 'See'"/>
    <xsl:if  test="see/*">
      <xsl:message  terminate="yes"  select="'ERROR: children of see-elements are not supported yet.'"/>
    </xsl:if>
    <xsl:if test=".//seealso">
      <xsl:message  terminate="no"   select="'WARNING: indexterm with seealso element(s). Not supported yet.'"/>
    </xsl:if>
    
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    
    <!-- mark the startofrange/endofrange-range with a bookmark and then reference that bookmark by use of the \r-switch of the XE field -->
    <xsl:if test="@class eq 'startofrange'">
      <w:bookmarkStart  w:id="{generate-id()}"  w:name="bm_{generate-id()}_"/>
    </xsl:if>
    
    <w:r>
      <w:t>XE &quot;</w:t>
    </w:r>
    <xsl:apply-templates select="primary" mode="#current"/>
    <xsl:if test="secondary">
      <w:r>
        <w:t>:</w:t>
      </w:r>
      <xsl:apply-templates select="secondary" mode="#current"/>
    </xsl:if>
    <xsl:if test="tertiary">
      <w:r>
        <w:t>:</w:t>
      </w:r>
      <xsl:apply-templates select="tertiary" mode="#current"/>
    </xsl:if>
    <w:r>
      <w:t>&quot;</w:t>
    </w:r>
    
    <!-- the \f-switch determines an index type -->
    <xsl:if test="@type">
      <w:r>
        <w:t xml:space="preserve"> \f <xsl:value-of select="@type"/></w:t>
      </w:r>
    </xsl:if>
    
    <!-- the \t-switch determines the text rendered in an index for this indexentry -->
    <xsl:if test="see">
      <w:r>
        <w:t xml:space="preserve"> \t &#x22;<xsl:if test="$see-prefix and $see-prefix ne ''"><xsl:value-of select="$see-prefix"/> </xsl:if><xsl:value-of select="see"/>&#x22;</w:t>
      </w:r>
    </xsl:if>
    
    <!-- the \r-switch determines that in an index the page-range of the bookmark will be rendered -->
    <xsl:if test="@class eq 'startofrange'">
      <w:r>
        <w:t>
          <xsl:value-of select="concat(' \r bm_', generate-id(), '_' )"/>
        </w:t>
      </w:r>
    </xsl:if>
    
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>
  
  <xsl:template match="primary | secondary | tertiary | see | seealso" mode="hub:default">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="indexterm//*[not(local-name() = ('subscript', 'superscript'))]" mode="hub:default" priority="-1">
    <xsl:message select="'hub2docx, unmapped children ', name(), ' in indexterm element.'"/>
    <xsl:choose>
      <xsl:when test="self::phrase or self::emphasis">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="node()" mode="#current"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template  match="index"  mode="hub:default">
    <xsl:apply-templates select="node()" mode="#current"/>
  </xsl:template>
  
  <xsl:template  match="index/title"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="IndexHeading"/>
      </w:pPr>
      <xsl:apply-templates select="node()" mode="#current"/>
    </w:p>
  </xsl:template>
  
  <xsl:template  match="indexentry"  mode="hub:default">
    <xsl:for-each select="*[ends-with(local-name(), 'yie')]">
      <xsl:apply-templates select="." mode="#current"/>
    </xsl:for-each>
    <xsl:if test="seeie or seealsoie">
      <xsl:message  terminate="no"  select="'WARNING: seeie and/or seealsoie-elements within indexentry. Not supported yet!'"/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template  match="indexentry/*[ends-with(local-name(), 'yie')]"  mode="hub:default">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="Index{if(local-name() eq 'primaryie') then '1' 
                               else if(local-name() eq 'secondaryie') then '2' 
                               else '3'}"/>
      </w:pPr>
      <xsl:apply-templates mode="#current"/>
    </w:p>
  </xsl:template>

</xsl:stylesheet>

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

  <!-- ISO 29500-1, 17.16.5.72, S. 1400 -->

  <!-- mark the startofrange/endofrange-range with a bookmark and then reference that bookmark by use of the \r-switch of the XE field -->
  <xsl:template  match="indexterm[ @class eq 'startofrange' ]"  mode="hub:default">
    <xsl:if  test="see">
      <xsl:message  terminate="yes"  select="'ERROR: see-elements within indexterm with @class=&quot;startofrange&quot; are not supported. Use @class=&quot;singular&quot; instead.'"/>
    </xsl:if>
    <w:bookmarkStart  w:id="{generate-id()}"  w:name="bm_{generate-id()}_"/>
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve">
        <xsl:value-of  select="concat(   'XE '
                                       , primary
                                       , if ( secondary ) then concat( ':', secondary) else ''
                                       , if ( tertiary )  then concat( ':', tertiary)  else ''
                                       , if ( @type )     then concat(' \f ', @type )  else ''		(: the \f-switch determines an index type :)
                                       , concat(' \r bm_', generate-id(), '_' )				(: the \r-switch determines that in an index the page-range of the bookmark will be rendered :)
                                     )"/>
      </w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>


  <!-- use a key to speed up the lookup -->
  <xsl:key name="startofrangeIndexterms"  match="//indexterm[ @class eq 'startofrange' ]"  use="@xml:id"/>
    
  <xsl:template  match="indexterm[ @class eq 'endofrange' ]"  mode="hub:default">
    <xsl:variable  name="correspondingStartofrangeIndexterm"  select="key(  'startofrangeIndexterms', @startref)"/>
    <w:bookmarkEnd  w:id="{$correspondingStartofrangeIndexterm/generate-id()}"/>
  </xsl:template>


  <xsl:template  match="indexterm[ @class eq 'singular' or not(@class) ]"  mode="hub:default">
    <xsl:if  test="see/*">
      <xsl:message  terminate="yes"  select="'ERROR: children of see-elements are not supported yet.'"/>
    </xsl:if>
    <w:r>
      <w:fldChar w:fldCharType="begin"/>
    </w:r>
    <w:r>
      <w:instrText xml:space="preserve">
        <xsl:value-of  select="concat(   'XE '
                                       , primary
                                       , if ( secondary ) then concat( ':', secondary)   else ''
                                       , if ( tertiary )  then concat( ':', tertiary)    else ''
                                       , if ( @type )     then concat(' \f ', @type )    else ''		(: the \f-switch determines an index type :)
                                       , if ( see )       then concat(' \t &#x22;See ', see, '&#x22;' )  else ''	(: the \t-switch determines the text rendered in an index for this indexentry :)
                                     )"/>
      </w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="end"/>
    </w:r>
  </xsl:template>


</xsl:stylesheet>

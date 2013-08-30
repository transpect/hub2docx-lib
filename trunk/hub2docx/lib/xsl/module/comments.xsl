<?xml version="1.0" encoding="UTF-8"?>

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

  <xsl:variable name="originalCommentIds" as="xs:string*"
    select="for $c in //annotation return generate-id($c)" />

  <xsl:function name="letex:comment-id" as="xs:integer">
    <xsl:param name="comment" as="element(annotation)" />
    <xsl:sequence select="index-of($originalCommentIds, generate-id($comment))" />
  </xsl:function>
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode="hub:default" -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="annotation" mode="hub:default">
    <w:commentRangeStart w:id="{letex:comment-id(.)}"/>
    <w:commentRangeEnd w:id="{letex:comment-id(.)}"/>
    <w:r>
      <w:rPr>
        <w:rStyle w:val="CommentReference"/>
      </w:rPr>
      <w:commentReference w:id="{letex:comment-id(.)}"/>
    </w:r>
  </xsl:template>


  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode="comments" -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="annotation" mode="comments">
    <w:comment w:id="{letex:comment-id(.)}" w:author="le-tex hub2docx" w:date="{current-dateTime()}" w:initials="h2d"><!--2013-08-30T10:47:00Z-->
      <xsl:apply-templates  mode="comments"/>
    </w:comment>
  </xsl:template>

  <xsl:template match="annotation/para" mode="comments" priority="3">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="CommentText"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:rStyle w:val="CommentReference"/>
        </w:rPr>
        <w:annotationRef/>
      </w:r>
      <xsl:apply-templates mode="hub:default" />
    </w:p>
  </xsl:template>

  <xsl:template match="annotation/*" mode="comments">
    <xsl:apply-templates select="." mode="hub:default" />
  </xsl:template>

  <xsl:template  match="node()"  mode="comments"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

</xsl:stylesheet>

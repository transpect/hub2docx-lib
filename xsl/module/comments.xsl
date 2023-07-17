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
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink o w m wp r"
>

  <!-- should pass it as a tunneled parameter in the comments and hub:default modes -->
  <xsl:variable name="originalCommentIds" as="xs:string*"
    select="for $c in //annotation return generate-id($c)" />

  <xsl:function name="tr:comment-id" as="xs:integer">
    <xsl:param name="comment" as="element(annotation)" />
    <xsl:sequence select="index-of($originalCommentIds, generate-id($comment)) - 1" />
  </xsl:function>
  
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode="hub:default" -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="annotation" mode="hub:default">
    <xsl:param  name="rPrContent"  as="element(*)*"  tunnel="yes"/><!-- w:… property elements -->
    <xsl:variable name="comment-id" select="if (preceding-sibling::node()[1][self::anchor[@xml:id and matches(@xml:id,'^comment_.*?_end$')]]) 
                                            then replace(preceding-sibling::anchor[1]/@xml:id,'^comment_(.*?)_end$','$1') 
                                            else tr:comment-id(.)"/>
    <xsl:if test="not(exists(preceding::anchor[not(matches(@xml:id,'_end$'))]
                                              [@xml:id and matches(@xml:id,concat('^comment_',$comment-id,'$'))]))">
      <w:commentRangeStart w:id="{$comment-id}"/>
    </xsl:if>
    <xsl:if test="not(exists(preceding::anchor[@xml:id and matches(@xml:id,concat('^comment_',$comment-id,'_end$'))]))">
      <w:commentRangeEnd w:id="{$comment-id}"/>
    </xsl:if>
    <w:r>
      <w:rPr>
        <xsl:call-template  name="mergeRunProperties">
          <xsl:with-param  name="inherited_rPrContent"  select="$rPrContent"  as="element(*)*"/>
          <xsl:with-param name="new_rPrContent" as="element(*)*">
            <xsl:if test="not($rPrContent/self::w:rStyle)">
              <w:rStyle w:val="CommentReference"/>  
            </xsl:if>
          </xsl:with-param>
        </xsl:call-template>
      </w:rPr>
      <w:commentReference w:id="{$comment-id}"/>
    </w:r>
  </xsl:template>

  <xsl:template match="anchor[@xml:id and matches(@xml:id,'^comment_.*?_end$')]" 
                mode="hub:default">
    <w:commentRangeEnd w:id="{replace(./@xml:id,'^comment_(.*?)_end$','$1')}"/>
  </xsl:template>
  
  <xsl:template match="anchor[@xml:id and matches(@xml:id,'^comment_.*?$')][not(matches(@xml:id,'_end$'))]" mode="hub:default">
    <w:commentRangeStart w:id="{replace(./@xml:id,'^comment_(.*?)$','$1')}"/>
  </xsl:template>

  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
  <!-- mode="comments" -->
  <!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template match="annotation" mode="comments">
    <xsl:variable name="comment-id" select="if (preceding-sibling::node()[1][self::anchor[@xml:id and matches(@xml:id,'^comment_.*?_end$')]]) 
                                            then replace(preceding-sibling::anchor[1]/@xml:id,'^comment_(.*?)_end$','$1') 
                                            else tr:comment-id(.)"/>
    <w:comment w:id="{$comment-id}" 
      w:author="{(info/author/personname/othername[@role = 'display-name'], 'le-tex hub2docx')[1]}"
      w:date="{(info/date, current-dateTime())[1] (: 2013-08-30T10:47:00Z :)}"
      w:initials="{(info/author/personname/othername[@role = 'initials'], 'h2d')[1]}">
      <xsl:apply-templates  mode="comments"/>
    </w:comment>
  </xsl:template>

  <xsl:template match="annotation/para" mode="comments" priority="3">
    <w:p>
      <xsl:apply-templates select="anchor[@role=('w14:paraId','w14:textId')]" mode="#current"/>
      <xsl:call-template name="hub:pPr">
        <xsl:with-param name="default-pPrs" as="element(w:pStyle)" tunnel="yes">
          <w:pStyle w:val="CommentText"/>
        </xsl:with-param>
      </xsl:call-template>
      <w:r>
        <w:rPr>
          <w:rStyle w:val="CommentReference"/>
        </w:rPr>
        <w:annotationRef/>
      </w:r>
      <xsl:apply-templates select="node() except  anchor[@role=('w14:paraId','w14:textId')]" mode="hub:default" />
    </w:p>
  </xsl:template>

  <xsl:template match="annotation/info" mode="comments" priority="2"/>
    
  <xsl:template match="annotation/*" mode="comments">
    <xsl:apply-templates select="." mode="hub:default" />
  </xsl:template>

  <xsl:template  match="node()"  mode="comments"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>

</xsl:stylesheet>

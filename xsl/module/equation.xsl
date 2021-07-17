<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
    xmlns:xsl		= "http://www.w3.org/1999/XSL/Transform"
    xmlns:xs		= "http://www.w3.org/2001/XMLSchema"
    xmlns:xsldoc	= "http://www.bacman.net/XSLdoc"
    xmlns:saxon		= "http://saxon.sf.net/"
    xmlns:saxExtFn	= "java:saxonExtensionFunctions"
    xmlns:hub		= "http://transpect.io/hub"
    xmlns:xlink		= "http://www.w3.org/1999/xlink"
    
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:omml		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:mml="http://www.w3.org/1998/Math/MathML"
    xmlns:css           = "http://www.w3.org/1996/css"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon saxExtFn hub xlink o w m omml wp r mml css"
>

  <xsl:import href="../omml/office16/MML2OMML.XSL" use-when="system-property('mml2omml') = 'office16'"/>
  <xsl:import href="../omml/mml2omml.xsl" use-when="not(system-property('mml2omml') = 'office16')"/>
  

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="inlineequation"  mode="hub:default">
    <xsl:variable name="rPrContent" as="element(w:rStyle)">
      <w:rStyle w:val="InlineEquation" />
    </xsl:variable>
    <xsl:apply-templates select="node()[not(self::text()[matches(., '^\s*$')])]" mode="#current">
      <xsl:with-param name="rPrContent" select="$rPrContent" as="element(*)+" tunnel="yes" />
    </xsl:apply-templates>
  </xsl:template>
  
  <xsl:template match="para[count(child::node())=1]
                           [phrase]/phrase[@* and (every $a in @* 
                                                   satisfies $a/name() =('css:color', 'css:background-color', 'css:font-size', 'css:font-weight', 'css:font-style', 'css:font-family', 'css:text-transform'))]
                                          [count(child::node())=1]
                                          [inlineequation]/inlineequation[count(child::node())=1]
                                                                         [m:math]" mode="hub:default">
    <m:oMathPara xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">
      <w:rPr>
        <xsl:apply-templates select="parent::*/(@css:color, 
          @css:background-color,
          @css:font-size, 
          @css:font-weight, 
          @css:font-style, 
          @css:font-family, 
          @css:text-transform)"  mode="props"/>        
      </w:rPr>
      <xsl:apply-templates mode="#current"/>
    </m:oMathPara>
  </xsl:template>

  <xsl:template  match="mathphrase"  mode="hub:default">
    <xsl:apply-templates mode="#current"/>
  </xsl:template>

  <xsl:template match="m:math" mode="hub:default">
    <m:oMath xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">
      <xsl:variable name="mml" as="element(mml:math)">
        <xsl:apply-templates select="." mode="m-to-mml"/>
      </xsl:variable>
      <xsl:call-template name="hub:mml2omml">
        <xsl:with-param name="mml" select="$mml"/>
      </xsl:call-template>
    </m:oMath>
  </xsl:template>
  
  <xsl:template name="hub:mml2omml">
    <xsl:param name="mml"/>
    <xsl:choose>
      <xsl:when test="system-property('mml2omml') = 'office16'">
        <xsl:apply-templates select="$mml"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$mml" mode="mml"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="m:math[m:mtable and
    (
      .//m:mspace[@linebreak='newline'] or
      .//m:maligngroup[(@columnalign = 'left') or (@groupalign = 'left')]
    )]" mode="hub:default" exclude-result-prefixes="mc w">
    <xsl:element name="m:oMathPara" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math">
      <xsl:for-each select="m:mtable/m:mtr">
        <xsl:element name="m:oMath" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math">
          <xsl:variable name="mml" as="node()">
            <xsl:apply-templates select="node()" mode="m-to-mml"/>
          </xsl:variable>
          <xsl:call-template name="hub:mml2omml">
            <xsl:with-param name="mml" select="$mml"/>
          </xsl:call-template>
          <xsl:if test="position() lt last()">
            <xsl:element name="m:r" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math">
              <xsl:element name="m:rPr" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math">
                <xsl:element name="m:sty" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math">
                  <xsl:attribute name="m:val" namespace="http://schemas.openxmlformats.org/officeDocument/2006/math"
                    select="'p'"/>
                </xsl:element>
              </xsl:element>
              <w:rPr>
                <w:rFonts w:ascii="Cambria Math" w:hAnsi="Cambria Math"/>
                <xsl:copy-of select="ancestor::w:p/w:pPr/w:rPr/w:sz"/>
                <w:lang w:val="en-US"/>
              </w:rPr>
              <w:br/>
            </xsl:element>
          </xsl:if>
        </xsl:element>
      </xsl:for-each>
    </xsl:element>
  </xsl:template>
  
  <xsl:template match="m:*" mode="m-to-mml">
    <xsl:element name="{local-name(.)}" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="node()[not(self::m:*)] | @*" mode="m-to-mml">
    <xsl:sequence select="."/>
  </xsl:template>

  <xsl:template  match="informalequation"  mode="hub:default">
    <w:p>
      <m:oMathPara xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math">
        <xsl:apply-templates mode="#current" />
      </m:oMathPara>
    </w:p>
  </xsl:template>

  <xsl:template match="omml:r[not(w:rPr)]" mode="hub:clean">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <w:rPr>
        <w:rFonts w:ascii="Cambria Math" w:hAnsi="Cambria Math"/>
        <xsl:copy-of select="ancestor::w:p/w:pPr/w:rPr/w:sz"/>
      </w:rPr>
      <xsl:apply-templates select="node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="omml:r/w:rPr[not(w:rFonts)]" mode="hub:clean">
    <xsl:copy>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
      <w:rFonts w:ascii="Cambria Math" w:hAnsi="Cambria Math"/>
      <xsl:copy-of select="ancestor::w:p/w:pPr/w:rPr/w:sz"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="w:tc/omml:oMath" mode="hub:clean">
    <w:p>
      <xsl:next-match/>
    </w:p>
  </xsl:template>

</xsl:stylesheet>

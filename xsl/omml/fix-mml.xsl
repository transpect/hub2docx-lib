<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:letex		= "http://www.le-tex.de/namespace"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:template match="node() | @*" mode="fix-mml">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:apply-templates mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:mover[not(count(*)=2)][parent::*:mtext]" mode="fix-mml">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:choose>
        <xsl:when test="*[1][preceding-sibling::text()[not(matches(.,'^\s*$'))]]">
          <mml:mtext>
            <xsl:value-of select="normalize-space(*[1]/preceding-sibling::text()[not(matches(.,'^\s*$'))])"/>
          </mml:mtext>
          <xsl:apply-templates select="*[1] | *[1]/following-sibling::node()" mode="#current"/>
        </xsl:when>
        <xsl:when test="*[1][following-sibling::text()[not(matches(.,'^\s*$'))]]">
          <xsl:apply-templates select="*[1] | *[1]/preceding-sibling::node()" mode="#current"/>
          <mml:mtext>
            <xsl:value-of select="normalize-space(*[1]/following-sibling::text()[not(matches(.,'^\s*$'))])"/>
          </mml:mtext>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:mtext[*:mover[not(count(*)=2)]]" mode="fix-mml">
    <xsl:variable name="current" select="."/>
    <mml:mrow>
      <xsl:for-each select="node()">
        <xsl:choose>
          <xsl:when test="self::*:mover[not(count(*)=2)]">
            <xsl:apply-templates select="." mode="#current"/>
          </xsl:when>
          <xsl:when test="self::text()[matches(.,'^\s*$')]"/>
          <xsl:otherwise>
            <xsl:element name="{name($current)}">
              <xsl:apply-templates select="$current/@*" mode="#current"/>
              <xsl:apply-templates select="." mode="#current"/>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </mml:mrow>
  </xsl:template>
  
  <xsl:template match="*[*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]][preceding-sibling::*]]" mode="fix-mml">
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="#current"/>
      <xsl:for-each-group select="node()" group-ending-with="*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]">
        <xsl:variable name="name" select="name(current-group()[last()])"/>
        <xsl:choose>
          <xsl:when test="current-group()[last()][self::*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]]">
            <xsl:for-each-group select="current-group()" group-starting-with="*[following-sibling::*[1][self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]]">
              <xsl:choose>
                <xsl:when test="current-group()[1][self::*[following-sibling::*[1][self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]]]">
                  <xsl:element name="{$name}">
                    <xsl:apply-templates select="current-group()[1]" mode="#current"/>
                    <xsl:apply-templates select="current-group()[last()]/*[2]" mode="#current"/>
                  </xsl:element>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:apply-templates select="current-group()" mode="#current"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each-group>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="current-group()" mode="#current"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[not(self::*:mrow)][preceding-sibling::*[1][self::*:munderover]]" mode="fix-mml">
    <xsl:variable name="fNary">
      <xsl:call-template name="isNary">
        <xsl:with-param name="ndCur" select="preceding-sibling::*[1]/child::*[1]" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$fNary='true'">
        <mml:mrow>
          <xsl:next-match/>
        </mml:mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:next-match/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="*:mrow[count(node()[self::* or self::text()[not(matches(.,'^\s*$'))]])=1][*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]]" mode="fix-mml">
    <xsl:message>
      TEST:
      <xsl:copy-of select="."/>
      :TEST
    </xsl:message>
    <xsl:next-match/>
  </xsl:template>
  
</xsl:stylesheet>
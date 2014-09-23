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
  
  <xsl:template match="*:mrow[count(node()[self::* or self::text()[not(matches(.,'^\s*$'))]])=1][*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]]]" mode="fix-mml">
    <xsl:message>
      TEST:
      <xsl:copy-of select="."/>
      :TEST
    </xsl:message>
    <xsl:next-match/>
  </xsl:template>
  
<!--  <xsl:template match="*:munderover[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])] | *:munder[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])] | *:mover[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])] | *:msub[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])] | *:msup[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])] | *:msubsup[letex:is-nary(child::*[1])][not(following-sibling::*[1][self::*:mrow])]">
    <xsl:message>
      TEST:
      <xsl:copy-of select="."/>
      :TEST
    </xsl:message>
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:function name="letex:is-nary">
    <!-\- ndCur is the element around the nAry operator -\->
    <xsl:param name="ndCur" />
    <xsl:variable name="sNdCur" select="normalize-space($ndCur)" />
    
    <xsl:variable name="fNaryOper">
      <xsl:call-template name="isNaryOper">
        <xsl:with-param name="sNdCur" select="$sNdCur" />
      </xsl:call-template>
    </xsl:variable>
    
    <!-\- Narys shouldn't be MathML accents.  -\->
    <xsl:variable name="fUnder" select="if ($ndCur/parent::*[self::*:munder]) then 1 else 0"/>
    
    <xsl:variable name="sLowerCaseAccent">
      <xsl:choose>
        <xsl:when test="$fUnder=1">
          <xsl:choose>
            <xsl:when test="$ndCur/parent::*[self::*:munder]/@accentunder">
              <xsl:value-of select="lower-case($ndCur/parent::*[self::*:munder]/@accentunder)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="lower-case($ndCur/parent::*[self::*:munder]/@*:accentunder)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="$ndCur/parent::*/@accent">
              <xsl:value-of select="lower-case($ndCur/parent::*/@accent)"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="lower-case($ndCur/parent::*/@*:accent)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <xsl:variable name="fAccent" select="if ($sLowerCaseAccent='true') then 1 else 0"/>
    
    <xsl:choose>
      <!-\- This ndCur is in fact part of an nAry if
      
           1)  The last descendant of ndCur (which could be ndCur itself) is an operator.
           2)  Along that chain of descendants we only encounter mml:mo, mml:mstyle, and mml:mrow elements.
           3)  the operator in mml:mo is a valid nAry operator
           4)  The nAry is not accented.
           -\->
      <xsl:when test="$fNaryOper = 'true'
        and $fAccent=0
        and $ndCur/descendant-or-self::*[last()]/self::*:mo
        and not($ndCur/descendant-or-self::*[not(self::*:mo or 
        self::*:mstyle or 
        self::*:mrow)])">
        <xsl:value-of select="true()" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="false()" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:template name="isNaryOper">
    <xsl:param name="sNdCur" />
    <xsl:value-of select="$sNdCur = ('&#x222B;', '&#x222C;', '&#x222D;', '&#x222E;', '&#x222F;', '&#x2230;', '&#x2232;', '&#x2233;', '&#x2231;', '&#x2229;', '&#x222A;', '&#x220F;', '&#x2210;', '&#x2211;', '&#x22C0;', '&#x22C1;', '&#x22C2;', '&#x22C3;')" />
  </xsl:template>-->
  
</xsl:stylesheet>
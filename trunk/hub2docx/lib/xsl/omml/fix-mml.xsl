<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:letex		= "http://www.le-tex.de/namespace"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  exclude-result-prefixes="xs letex"
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
  
  <xsl:template match="*[descendant-or-self::*:mrow[count(node()[self::* or self::text()[not(matches(.,'^\s*$'))]])=1]
                                                   [*[self::*:msub or self::*:msup]
                                                     [child::*[1][self::*:mrow[not(child::node())]]]
                                                   ]
                        ]
                        [preceding-sibling::node()[self::* or self::text()[not(matches(.,'^\s*$'))]]]
                        [not(descendant::*[descendant-or-self::*:mrow[count(node()[self::* or self::text()[not(matches(.,'^\s*$'))]])=1]
                                                                     [*[self::*:msub or self::*:msup]
                                                                       [child::*[1][self::*:mrow[not(child::node())]]]
                                                                     ]
                                          ]
                                          [preceding-sibling::node()[self::* or self::text()[not(matches(.,'^\s*$'))]]])
                        ]" mode="fix-mml">
    <xsl:call-template name="replace-empty-mrow">
      <xsl:with-param name="context" select="." as="node()"/>
      <xsl:with-param name="content" select="preceding-sibling::node()[self::* or self::text()[not(matches(.,'^\s*$'))]][1]" as="node()"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="node()[self::* or self::text()[not(matches(.,'^\s*$'))]]
                             [following-sibling::*[1]
                                                  [self::*[descendant-or-self::*:mrow[count(node()[self::* or self::text()[not(matches(.,'^\s*$'))]])=1]
                                                                                     [*[self::*:msub or self::*:msup]
                                                                                       [child::*[1][self::*:mrow[not(child::node())]]]
                                                                                     ]
                                                          ]
                                                          [not(descendant::*[descendant-or-self::*:mrow[count(node()[self::* or
                                                                                                                     self::text()[not(matches(.,'^\s*$'))]
                                                                                                                    ])=1
                                                                                                       ]
                                                                                                       [*[self::*:msub or self::*:msup]
                                                                                                         [child::*[1][self::*:mrow[not(child::node())]]]
                                                                                                       ]
                                                                            ]
                                                                            [preceding-sibling::node()[self::* or self::text()[not(matches(.,'^\s*$'))]]])
                                                          ]
                                                  ]
                             ]" mode="fix-mml">
    <xsl:param name="display" select="false()"/>
    
    <xsl:if test="$display">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="*[*:mo[not(@stretchy)][matches(.,'^(\(|\))$')]][count(*:mo[not(@stretchy)][matches(.,'^\)$')])=count(*:mo[not(@stretchy)][matches(.,'^\($')])]" mode="fix-mml">
    <xsl:call-template name="mo-to-mfenced">
      <xsl:with-param name="context" select="."/>
      <xsl:with-param name="bracket-type" select="'\('"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="*[*:mo[not(@stretchy)][matches(.,'^(\{|\})$')]][count(*:mo[not(@stretchy)][matches(.,'^\}$')])=count(*:mo[not(@stretchy)][matches(.,'^\{$')])]" mode="fix-mml">
    <xsl:call-template name="mo-to-mfenced">
      <xsl:with-param name="context" select="."/>
      <xsl:with-param name="bracket-type" select="'\{'"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template match="*[*:mo[not(@stretchy)][matches(.,'^(\[|\])$')]][count(*:mo[not(@stretchy)][matches(.,'^\]$')])=count(*:mo[not(@stretchy)][matches(.,'^\[$')])]" mode="fix-mml">
    <xsl:call-template name="mo-to-mfenced">
      <xsl:with-param name="context" select="."/>
      <xsl:with-param name="bracket-type" select="'\['"/>
    </xsl:call-template>
  </xsl:template>
  
  <xsl:template name="mo-to-mfenced">
    <xsl:param name="context" as="node()"/>
    <xsl:param name="bracket-type" as="xs:string"/>

    <xsl:variable name="new-context">
      <xsl:element name="{$context/name()}">
        <xsl:apply-templates select="$context/@*" mode="#current"/>
        <xsl:for-each-group select="$context/node()" group-starting-with="*:mo[not(@stretchy)][matches(.,concat('^',$bracket-type,'$'))]">
          <xsl:for-each-group select="current-group()" group-ending-with="*:mo[not(@stretchy)][matches(.,concat('^',if ($bracket-type='\(') then '\)' else if ($bracket-type='\{') then '\}' else '\]','$'))]">
            <xsl:choose>
              <xsl:when test="current-group()[1][self::*:mo[not(@stretchy)][matches(.,concat('^',$bracket-type,'$'))]] and current-group()[last()][self::*:mo[not(@stretchy)][matches(.,concat('^',if ($bracket-type='\(') then '\)' else if ($bracket-type='\{') then '\}' else '\]','$'))]]">
                <mml:mfenced open="{if ($bracket-type='\(') then '(' else if ($bracket-type='\{') then '{' else '['}" close="{if ($bracket-type='\(') then ')' else if ($bracket-type='\{') then '}' else ']'}">
                  <xsl:apply-templates select="current-group()[position() gt 1][position() lt last()]" mode="#current"/>
                </mml:mfenced>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="#current"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:for-each-group>
      </xsl:element>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$new-context/*:mo[not(@stretchy)][matches(.,concat('^(',$bracket-type,'|',if ($bracket-type='\(') then '\)' else if ($bracket-type='\{') then '\}' else '\]',')$'))] and count($new-context/*:mo[not(@stretchy)][matches(.,concat('^',if ($bracket-type='\(') then '\)' else if ($bracket-type='\{') then '\}' else '\]','$'))])=count($new-context/*:mo[not(@stretchy)][matches(.,concat('^',$bracket-type,'$'))])">
        <xsl:call-template name="mo-to-mfenced">
          <xsl:with-param name="context" select="$new-context"/>
          <xsl:with-param name="bracket-type" select="$bracket-type"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$new-context"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="replace-empty-mrow">
    <xsl:param name="context" as="node()"/>
    <xsl:param name="content" as="node()"/>
    
    <xsl:choose>
      <xsl:when test="$context[self::*:mrow[not(child::node())]]">
        <mml:mrow>
          <xsl:apply-templates select="$content" mode="#current">
            <xsl:with-param name="display" select="true()"/>
          </xsl:apply-templates>
        </mml:mrow>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{name($context)}">
          <xsl:call-template name="replace-empty-mrow">
            <xsl:with-param name="context" select="$context/node()[self::* or self::text()[not(matches(.,'^\s*$'))]][1]"/>
            <xsl:with-param name="content" select="$content"/>
          </xsl:call-template>
          <xsl:apply-templates select="$context/node() except $context/node()[self::* or self::text()[not(matches(.,'^\s*$'))]][1]" mode="#current"/>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
</xsl:stylesheet>
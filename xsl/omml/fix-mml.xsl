<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
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
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:value-of select="normalize-space(*[1]/preceding-sibling::text()[not(matches(.,'^\s*$'))])"/>
          </mml:mtext>
          <xsl:apply-templates select="*[1] | *[1]/following-sibling::node()" mode="#current"/>
        </xsl:when>
        <xsl:when test="*[1][following-sibling::text()[not(matches(.,'^\s*$'))]]">
          <xsl:apply-templates select="*[1] | *[1]/preceding-sibling::node()" mode="#current"/>
          <mml:mtext>
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:value-of select="normalize-space(*[1]/following-sibling::text()[not(matches(., '^\s*$'))])"/>
          </mml:mtext>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:mtext[not(@xml:space)]" mode="fix-mml" priority="0">
    <xsl:copy>
      <xsl:attribute name="xml:space" select="'preserve'"/>
      <xsl:apply-templates select="@*, node()" mode="#current"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*:mtext[*:mover[not(count(*)=2)]]" mode="fix-mml" xmlns="http://www.w3.org/1998/Math/MathML">
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
  
  <xsl:template match="*[*[self::*:msub or self::*:msup][child::*[1][self::*:mrow[not(child::node())]]][preceding-sibling::*]]" mode="fix-mml" xmlns="http://www.w3.org/1998/Math/MathML">
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
  
  <xsl:template match="*[not(self::*:mrow)][preceding-sibling::*[1][self::*:munderover or self::*:munder]]" mode="fix-mml">
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
  
  <xsl:template name="replace-empty-mrow" xmlns="http://www.w3.org/1998/Math/MathML">
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
  
  <xsl:variable name="opening-parenthesis" select="'[\[\{\(]'"/>
  <xsl:variable name="closing-parenthesis" select="'[\]\}\)]'"/>
  
  <xsl:template match="*[descendant::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]
                        [descendant::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]
                        [child::*:mo[not(@stretchy='false')][matches(.,concat('^(',$opening-parenthesis,'|',$closing-parenthesis,')$'))]]
                        [not( ancestor::*[child::*:mo[not(@stretchy='false')][matches(.,concat('^(',$opening-parenthesis,'|',$closing-parenthesis,')$'))]])]" mode="fix-mml">
    <xsl:param name="processed" select="false()"/>
    <xsl:choose>
      <xsl:when test="$processed">
        <xsl:next-match/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy>
          <xsl:apply-templates select="@*" mode="#current"/>
          <xsl:call-template name="repair-parenthesis">
            <xsl:with-param name="context" select="node()"/>
          </xsl:call-template>
        </xsl:copy>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template name="repair-parenthesis" xmlns="http://www.w3.org/1998/Math/MathML">
    <xsl:param name="context" as="node()*"/>
    <xsl:choose>
      <xsl:when test="not($context/descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^(',$opening-parenthesis,'|',$closing-parenthesis,')$'))])">
        <xsl:apply-templates select="$context" mode="fix-mml">
          <xsl:with-param name="processed" select="true()"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="(count($context/descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]) gt 1 and count($context/descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]) = 0) or (count($context/descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]) = 0 and count($context/descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]) gt 1)">
        <xsl:apply-templates select="$context" mode="fix-mml">
          <xsl:with-param name="processed" select="true()"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:when test="count($context/descendant-or-self::*:mo[not(@stretchy='false')]
                                                             [matches(.,concat('^(',$opening-parenthesis,'|',$closing-parenthesis,')$'))]) = 1">
        <xsl:for-each-group select="$context" 
                            group-starting-with="*[descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]">
          <xsl:for-each-group select="current-group()"
                              group-ending-with="*[descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]">
            <xsl:choose>
              <xsl:when test="current-group()[1][self::*[descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]]                                  or 
                              current-group()[last()]
                                             [self::*[descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]]">
                <xsl:choose>
                  <xsl:when test="current-group()[1][self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]">
                    <mml:mfenced open="{current-group()[1]}" close="" separators="">
                      <xsl:apply-templates select="current-group()[position() gt 1]" mode="fix-mml">
                        <xsl:with-param name="processed" select="true()"/>
                      </xsl:apply-templates>
                    </mml:mfenced>
                  </xsl:when>
                  <xsl:when test="current-group()[last()]
                    [self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]">
                    <mml:mfenced open="" close="{current-group()[last()]}" separators="">
                      <xsl:apply-templates select="current-group()[position() lt last()]" mode="fix-mml">
                        <xsl:with-param name="processed" select="true()"/>
                      </xsl:apply-templates>
                    </mml:mfenced>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:choose>
                      <xsl:when test="current-group()[1][self::*[descendant::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]]">
                        <xsl:element name="{current-group()[1]/name()}">
                          <xsl:sequence select="current-group()[1]/@*"/>
                          <xsl:call-template name="repair-parenthesis">
                            <xsl:with-param name="context" select="current-group()[1]/node()"/>
                          </xsl:call-template>
                        </xsl:element>
                        <xsl:apply-templates select="current-group()[position() gt 1]" mode="fix-mml">
                          <xsl:with-param name="processed" select="true()"/>
                        </xsl:apply-templates>
                      </xsl:when>
                      <xsl:when test="current-group()[last()]
                                                     [self::*[descendant::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]]">
                        <xsl:apply-templates select="current-group()[position() lt last()]" mode="fix-mml">
                          <xsl:with-param name="processed" select="true()"/>
                        </xsl:apply-templates>
                        <xsl:element name="{current-group()[last()]/name()}">
                          <xsl:sequence select="current-group()[last()]/@*"/>
                          <xsl:call-template name="repair-parenthesis">
                            <xsl:with-param name="context" select="current-group()[last()]/node()"/>
                          </xsl:call-template>
                        </xsl:element>
                      </xsl:when>
                    </xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="fix-mml">
                  <xsl:with-param name="processed" select="true()"/>
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:for-each-group>
      </xsl:when>
      <!-- example for the following xsl:when case:
        <mrow><mi mathvariant="normal">a</mi><mo>(</mo><msub><mi mathvariant="normal">p</mi><mi mathvariant="normal">i</mi></msub><mo>÷</mo><mover accent="true"><mi mathvariant="normal">p</mi><mo>‾</mo></mover><msup><mo>)</mo><mi mathvariant="normal">b</mi></msup></mrow> -->
      <xsl:when test="$context/self::*:mo[not(@stretchy='false')]
                                         [matches(., concat('^(', $opening-parenthesis, ')$'))]
                      and (
                        every $open in $context/self::*:mo[not(@stretchy='false')]
                                                          [matches(., concat('^(', $opening-parenthesis, ')$'))]
                        satisfies $open[
                          following-sibling::*[
                            self::*:mo[not(@stretchy='false')]
                                      [matches(., concat('^(', $opening-parenthesis, '|', $closing-parenthesis, ')$'))] or 
                            self::*[local-name() = ('msub', 'msup')]
                                   [*[1][self::*:mo[not(@stretchy='false')]][matches(., concat('^(', $closing-parenthesis, '|', $closing-parenthesis, ')$'))]]
                          ][1][
                           self::*:mo[not(@stretchy='false')][matches(., concat('^(', $closing-parenthesis, ')$'))]
                           or
                           self::*[local-name() = ('msub', 'msup')]
                             /*[1][self::*:mo[not(@stretchy='false')]][matches(., concat('^(', $closing-parenthesis, ')$'))]
                          ]
                        ]
                      )">
        <xsl:for-each-group select="$context"
          group-starting-with="*:mo[not(@stretchy='false')]
                                   [matches(., concat('^(', $opening-parenthesis, ')$'))]">
          <xsl:for-each-group select="current-group()"
            group-ending-with="*[
                                  (
                                    local-name() = ('msub', 'msup') and
                                    *[1][self::*:mo[not(@stretchy='false')]][matches(., concat('^(', $closing-parenthesis, ')$'))]
                                  ) or
                                  (
                                    self::*:mo[not(@stretchy='false')][matches(., concat('^(', $closing-parenthesis, ')$'))]
                                  )
                                ]">
            <xsl:choose>
              <xsl:when test="current-group()[last()][self::*[local-name() = ('msub', 'msup')]
                                                             [*[1][self::*:mo[not(@stretchy='false')]][matches(., concat('^(', $closing-parenthesis, ')$'))]]]">
                <mml:mfenced open="{current-group()[1]}" close="{current-group()[last()]/self::*[local-name() = ('msub', 'msup')]/*[1]}" separators="">
                  <xsl:element name="{local-name(current-group()[last()]/self::*[local-name() = ('msub', 'msup')])}">
                    <mml:mrow>
                      <xsl:apply-templates select="current-group()[position() != 1 and position() != last()]" mode="fix-mml">
                        <xsl:with-param name="processed" select="true()"/>
                      </xsl:apply-templates>
                    </mml:mrow>
                    <xsl:apply-templates select="current-group()[last()]/*[position() != 1]" mode="fix-mml">
                      <xsl:with-param name="processed" select="true()"/>
                    </xsl:apply-templates>
                  </xsl:element>
                </mml:mfenced>
              </xsl:when>
              <xsl:when test="current-group()[last()]/self::*:mo[not(@stretchy='false')][matches(., concat('^(', $closing-parenthesis, ')$'))]">
                <mml:mfenced open="{current-group()[1]}" close="{current-group()[last()]}" separators="">
                  <mml:mrow>
                    <xsl:apply-templates select="current-group()[position() != 1 and position() != last()]" mode="fix-mml">
                      <xsl:with-param name="processed" select="true()"/>
                    </xsl:apply-templates>
                  </mml:mrow>
                </mml:mfenced>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates select="current-group()" mode="fix-mml">
                  <xsl:with-param name="processed" select="true()"/>
                </xsl:apply-templates>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each-group>
        </xsl:for-each-group>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="temp" as="node()*">
        <xsl:for-each-group select="$context" group-starting-with="*[descendant-or-self::*:mo[not(@stretchy='false')]
                                                                                             [matches(.,concat('^',$opening-parenthesis,'$'))]]">
          <xsl:choose>
            <xsl:when test="current-group()[1]
                                           [descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]">
              <xsl:for-each-group select="current-group()" 
                                  group-ending-with="*[descendant-or-self::*:mo[not(@stretchy='false')]
                                                                               [matches(.,concat('^',$closing-parenthesis,'$'))]]">
                <xsl:choose>
                  <xsl:when test="current-group()
                    [last()][descendant-or-self::*:mo[not(@stretchy='false')]
                    [matches(.,concat('^',$closing-parenthesis,'$'))]] and current-group()[1]
                    [descendant-or-self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]">
                    <xsl:choose>
                      <xsl:when test="count(current-group())=1">
                        <xsl:element name="{current-group()/name()}">
                          <xsl:sequence select="current-group()/@*"/>
                          <xsl:call-template name="repair-parenthesis">
                            <xsl:with-param name="context" select="current-group()/node()"/>
                          </xsl:call-template>
                        </xsl:element>
                      </xsl:when>
                      <xsl:when test="current-group()[1][self::*:mo[not(@stretchy='false')]
                        [matches(.,concat('^',$opening-parenthesis,'$'))]
                        ] and current-group()[last()][self::*:mo[not(@stretchy='false')]
                        [matches(.,concat('^',$closing-parenthesis,'$'))]]">
                        <mml:mfenced open="{current-group()[1]}" close="{current-group()[last()]}" separators="">
                          <xsl:sequence select="current-group()[position() gt 1][position() lt last()]"/>
                        </mml:mfenced>
                      </xsl:when>
                      <xsl:when test="current-group()[self::*][1][self::*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]] and count(current-group()[self::*])=2">
                        <xsl:element name="{current-group()[self::*][2]/name()}">
                          <xsl:sequence select="current-group()[self::*][1]"/>
                          <xsl:sequence select="current-group()[position() gt 1]/node()"/>
                        </xsl:element>
                      </xsl:when>
                      <xsl:when test="current-group()[self::*][last()][self::*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]] and count(current-group()[self::*])=2">
                        <xsl:element name="{current-group()[self::*][1]/name()}">
                          <xsl:sequence select="current-group()[self::*][position() lt last()]/node()"/>
                          <xsl:sequence select="current-group()[self::*][last()]"/>
                        </xsl:element>
                      </xsl:when>
                      <xsl:when test="current-group()[1][self::*:mrow[*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]] or current-group()[last()][self::*:mrow[*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]]">
                        <xsl:choose>
                          <xsl:when test="current-group()[1][self::*:mrow[*:mo[not(@stretchy='false')][matches(.,concat('^',$opening-parenthesis,'$'))]]]">
                            <xsl:sequence select="current-group()[1]/node()"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:sequence select="current-group()[1]"/>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:sequence select="current-group()[position() gt 1][position() lt last()]"/>
                        <xsl:choose>
                          <xsl:when test="current-group()[last()][self::*:mrow[*:mo[not(@stretchy='false')][matches(.,concat('^',$closing-parenthesis,'$'))]]]">
                            <xsl:sequence select="current-group()[last()]/node()"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:sequence select="current-group()[last()]"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:message>
                          TO_DO: Parentheses in different levels. Implementation required!
                          <xsl:sequence select="current-group()"/>
                          NAMES: <xsl:for-each select="current-group()">
                            <xsl:value-of select="name(), ' '"/>
                          </xsl:for-each>
                        </xsl:message>
                        <xsl:sequence select="current-group()"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:sequence select="current-group()"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:when>
            <xsl:otherwise>
              <xsl:sequence select="current-group()"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="not(deep-equal($context,$temp))">
            <xsl:call-template name="repair-parenthesis">
              <xsl:with-param name="context" select="$temp"/>
            </xsl:call-template>  
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="$temp" mode="fix-mml">
              <xsl:with-param name="processed" select="true()"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
<!-- KW 2016-02-24: subsup, weil sonst Indizes bei Primes im Gegensatz zum MathType in OMML zusätzlichen Abstand erhalten  -->
  <xsl:template match="*:msub[*[1][self::*:msup[*[2][self::*:mo[.='&#x2032;']]]]]" mode="fix-mml">
    <mml:msubsup>
      <xsl:apply-templates select="*[1]/*[1]" mode="#current"/>
      <xsl:apply-templates select="*[2]" mode="#current"/>
      <xsl:apply-templates select="*[1]/*[2]" mode="#current"/>
    </mml:msubsup>
  </xsl:template>
  
  <xsl:template match="mml:mover/child::*[2][self::mml:mo][. = '&#x203e;']" mode="fix-mml">
    <xsl:copy>
      <xsl:value-of select="'&#x305;'"/>
    </xsl:copy>
  </xsl:template>
  
</xsl:stylesheet>
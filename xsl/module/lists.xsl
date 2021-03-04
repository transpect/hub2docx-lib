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
    xmlns:css           = "http://www.w3.org/1996/css"

    xmlns:o		= "urn:schemas-microsoft-com:office:office"
    xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
    xmlns:w		= "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:m		= "http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:wp		= "http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
    xmlns:r		= "http://schemas.openxmlformats.org/package/2006/relationships"

    xpath-default-namespace = "http://docbook.org/ns/docbook"

    exclude-result-prefixes = "xsl xs xsldoc saxon tr saxExtFn hub xlink o w m wp r css"
>


  <xsl:variable name="hub:list-element-names" as="xs:string+" select="( 'itemizedlist' , 'orderedlist', 'bibliography', 'bibliodiv', 'variablelist' )"/>

<!-- ================================================================================ -->
<!-- helper functions -->
<!-- ================================================================================ -->


  <!-- This list is used in order to speed up the index-of(), which would be extremly time consuming if operating on the sequence of lists itself. -->
  <xsl:variable  name="generatedIdOfAllLists">
    <xsl:for-each  select="//*[ local-name() = $hub:list-element-names]">
      <!-- the tr:-namespace is used here for clarity, because we use 'xpath-default-namespace = "http://docbook.org/ns/docbook"' and the result of that would not be expected -->
      <tr:list>
        <tr:id><xsl:value-of select="generate-id()"/></tr:id>
        <tr:pos><xsl:value-of select="position()"/></tr:pos>
      </tr:list>
    </xsl:for-each>
  </xsl:variable>


  <!-- The value numId/@val identifies a list unambiguously.
       This function returns an unambiguous numId/@val for the list-node given as argument, which is not already in use in the template numbering.xml document. -->
  <xsl:function  name="tr:getNumId">
    <xsl:param  name="generatedIdOfList"  as="xs:string"/>
    <xsl:choose>
      <xsl:when  test="$generatedIdOfAllLists//tr:list[ ./tr:id eq $generatedIdOfList ]">
        <xsl:value-of  select="1001 + $generatedIdOfAllLists//tr:list[ ./tr:id eq $generatedIdOfList ]/tr:pos - 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message  terminate="no"   select="$generatedIdOfAllLists"/>
        <xsl:message  terminate="no"   select="$generatedIdOfList"/>
        <xsl:message  terminate="yes"  select="'ERROR: tr:getNumId() could not find a list-id in the global variable $generatedIdOfAllLists'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="tr:get-abstractNumId-by-role" as="xs:integer?">
    <xsl:param name="role" as="xs:string+"/>
    <xsl:sequence 
      select="(collection()//w:numbering/w:num[@w:numId = (collection()//w:styles/w:style[@w:styleId = $role]/w:pPr/w:numPr/w:numId/@w:val)[1]]/w:abstractNumId/@w:val,
               (collection()//w:numbering/w:abstractNum[w:lvl/w:pStyle/@w:val = $role]/@w:abstractNumId)[1])[1]"/>
  </xsl:function>

  <xsl:function  name="tr:getAbstractNumId" as="xs:integer">
    <xsl:param  name="list"  as="node()"/>
    <!-- §§§ This assignment is source data specific and has to be adapted according to the list types occuring.
             Please note that is very easy to adapt the style-information related to this abstractNumIds by running Microbugs Office 2007 Word. -->
    <!-- § I use values starting from 10 here, because the current template contains <w:multiLevelType w:val="hybridMultilevel"/>-lists there. -->
    <xsl:value-of  select="if      ( $list[ self::itemizedlist[ not( @mark) ] ] )			then 14 
                           else if ( $list[ self::itemizedlist[ @mark eq 'nomark' ] ] )			then 11
                           else if ( $list[ self::itemizedlist[ @mark eq 'note' ] ] )			then 12
                           else if ( $list[ self::itemizedlist[ @mark eq 'thumb' ] ] )			then 36
                           else if ( $list[ self::orderedlist [ not( @mark) ] ] )			then 13 
                           else if ( $list[ self::orderedlist [ @numeration eq 'loweralpha' ] ] )	then 15
                           else if ( $list[ self::bibliography[ every $bi in .//bibliomisc satisfies $bi/@role = 'numberedRef' ] ] )			then 0
                           else if ( $list[ self::bibliodiv[ every $bi in .//bibliomisc satisfies $bi/@role = 'numberedRef' ] ] )			then 0
                           else if ( $list[ self::bibliography ] )			then 38
                           else if ( $list[ self::bibliodiv ] )			then 38
                           else error( (), concat(   'ERROR: list type could not be determined. Please enlighten tr:getAbstractNumId() how to guess it.&#x0A;'
                                                   , 'list element name: ', $list/local-name(), '&#x0A;'
                                                   , for $attr in $list/@* return concat( 'attribute @', $attr/local-name(), ' = ', $attr, '', '&#x0A;')
                                                 ))
                          "/>
  </xsl:function>

  <!-- This function provides the integer equivalent of a listitem's number. -->
  <xsl:function name="tr:getLiNumAsInt" as="xs:integer?">
    <xsl:param name="num" as="xs:string?"/>
    <xsl:param name="numeration" as="xs:string?"><!-- arabic, loweralpha, lowerroman, upperalpha, upperroman --></xsl:param>
    <xsl:variable name="cleanNum" as="xs:string" select="replace(replace($num, '^[\s\p{Zs}\[\(]*([^\.\]\) ]+)[\.\]\) ]*$', '$1'),
                                                                 '^(\d+\.)+(\d+\.?)$', '$2')"/>
    <xsl:choose>
      <xsl:when test="not($num)"/>
      <xsl:when test="$numeration eq 'arabic' and ($cleanNum castable as xs:integer)">
        <xsl:sequence select="xs:integer($cleanNum)"/>
      </xsl:when>
      <xsl:when test="$numeration eq 'arabic'">
        <xsl:message select="'tr:getLiNumAsInt: Value', $num, 'cleaned as ', $cleanNum, 'may not be cast to integer'"/>        
      </xsl:when>
      <xsl:when test="$numeration = ('loweralpha', 'upperalpha')">
        <xsl:sequence select="tr:letters-to-number($cleanNum)"/>
      </xsl:when>
      <xsl:when test="$numeration = ('lowerroman', 'upperroman')">
        <xsl:sequence select="tr:roman-to-int($cleanNum)"/>
      </xsl:when>
      <xsl:when test="matches($cleanNum, '^[0-9]+$')"><!-- arabic -->
        <xsl:value-of select="$cleanNum"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:function>
  
  <!-- This function identifies whether a list starts or continues a preceding list. -->
  <xsl:function name="tr:isContinuedList" as="xs:boolean">
    <xsl:param name="list" as="element()"/>
    <xsl:choose>
      <xsl:when test="$list/listitem[1][@override]">
        <xsl:variable name="num" as="xs:string" select="$list/listitem[1]/@override"/>
        <xsl:variable name="type" as="xs:string" select="tr:getNumerationType($list)"/>
        <xsl:variable name="possiblyContinuedList" as="element()?" 
                      select="($list/preceding-sibling::*[ local-name() = $hub:list-element-names]
                                                         [listitem[1][@override][matches(@override, '^[\(]?[aA1iI][\.\)]?')]])[1]"/>
        <xsl:variable name="possiblyContinuedListSeq" as="element()*"
                      select="$possiblyContinuedList, 
                              $list/preceding-sibling::*[ local-name() = $hub:list-element-names]
                                                        [preceding-sibling::*[. is $possiblyContinuedList]]"/>
        <xsl:sequence select=" if (tr:getLiNumAsInt($num, $type) = 1)
                               then false()
                               else if (    exists($possiblyContinuedList) 
                                        and
                                            (  tr:getLiNumAsInt($num, $type) 
                                             - tr:getLiNumAsInt($possiblyContinuedListSeq[last()]/listitem[last()]/@override, 
                                                               (tr:getNumerationType($possiblyContinuedList))) 
                                               = 1)
                                        )
                                    then true()
                                    else false()"/>
      </xsl:when>
      <xsl:when test="$list/@continuation eq 'continues'">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <!-- This function examines whether the current number is the ordinary follower of the preceding number. -->
  <xsl:function name="tr:isOrdinaryFollower" as="xs:boolean">
    <xsl:param name="elt" as="element()"/>
    <xsl:variable name="currentNum" as="xs:integer?" 
      select="tr:getLiNumAsInt($elt/@override, tr:getNumerationType($elt/ancestor::*[local-name() = $hub:list-element-names][1]))"/>
    <xsl:variable name="precedingNum" as="xs:integer?" 
      select="(tr:getLiNumAsInt($elt/preceding-sibling::*[1]/@override, tr:getNumerationType($elt/ancestor::*[local-name() = $hub:list-element-names][1])), 0)[1]"/>
    <xsl:sequence select="boolean(($currentNum - $precedingNum) = 1)"/>
  </xsl:function>
  
  <!-- This function calculates new starting numbers within lists as a sequence of integer values. 
       For example: 'b)', 'd)' will return '2 4'. -->
  <xsl:function name="tr:getOverrideStarts" as="xs:integer*">
    <xsl:param name="list" as="element()"/>
    <xsl:choose>
      <xsl:when test="$list/local-name() = ('itemizedlist', 'variablelist')">
        <xsl:sequence select="1"/>
      </xsl:when>      
      <xsl:otherwise>
        <xsl:variable name="numeration" as="xs:string" select="tr:getNumerationType($list)"/>
        <xsl:variable name="numbers" as="xs:integer*" 
          select="for $li in $list/* return (if ($li/@override[normalize-space()]) 
                                             then if (not(tr:isOrdinaryFollower($li)))
                                                  then tr:getLiNumAsInt($li/@override, $numeration)
                                                  else 1
                                             else ())"/>
        <xsl:sequence select="$numbers"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="tr:getLastOverrideStart" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    <xsl:variable name="li" as="element(listitem)" select="$elt/ancestor-or-self::listitem[1]"/>
    <xsl:variable name="numeration" as="xs:string" select="tr:getNumerationType($li/parent::*)"/>
    <xsl:variable name="lastOverrideStart" as="xs:integer" 
      select="($li/preceding-sibling::*[not(tr:isOrdinaryFollower(.))][1]/tr:getLiNumAsInt(@override, $numeration), 1)[1]"/>
    <xsl:variable name="currentNumAsInt" as="xs:integer?" select="tr:getLiNumAsInt($li/@override, $numeration)"/>
    <xsl:sequence select="if ($li/@override[normalize-space()]) 
                          then  if (tr:isOrdinaryFollower($li))
                                then $lastOverrideStart
                                else  if(xs:string($currentNumAsInt) != '')
                                      then $currentNumAsInt
                                      else $lastOverrideStart
                          else $lastOverrideStart"/>
  </xsl:function>
  
  <!-- This function selects the ilvl value. -->
  <xsl:function name="tr:getIlvl" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    <xsl:sequence select="count($elt/ancestor-or-self::*[local-name() = $hub:list-element-names]) - 1"/>
  </xsl:function>
  
  <!-- This function calculates the numId for a single listitem or para. -->
  <xsl:function name="tr:getLiNumId" as="xs:integer">
    <xsl:param name="elt" as="element()"/>
    <xsl:param name="overrideStart" as="xs:integer"/>
    <xsl:sequence select="xs:integer(tr:getNumId(generate-id($elt/ancestor-or-self::*[local-name() = $hub:list-element-names][1])) 
                          * 1000
                          + $overrideStart)"/>
  </xsl:function>
  
  <xsl:function name="tr:getNumerationType" as="xs:string?">
    <xsl:param name="list" as="element()"/>
    <xsl:variable name="givenNumeration" as="xs:string?" select="$list/@numeration"/>
    <xsl:variable name="nums" as="xs:string*" 
      select="for $o in $list/listitem/@override return replace($o, '^\s?[\(]?([^\.\)\( ]+)[\.\) ]*$', '$1')"/>
    <xsl:choose>
      <xsl:when test="    ($givenNumeration eq 'arabic')
                      and (every $num in $nums satisfies matches($num, '^[0-9]+$'))">arabic</xsl:when>
      <xsl:when test="    ($givenNumeration eq 'loweralpha')
                      and (every $num in $nums satisfies matches($num, '^[a-z]+$'))">loweralpha</xsl:when>
      <xsl:when test="    ($givenNumeration eq 'upperalpha')
                      and (every $num in $nums satisfies matches($num, '^[A-Z]+$'))">upperalpha</xsl:when>
      <xsl:when test="    ($givenNumeration eq 'lowerroman')
                      and (every $num in $nums satisfies matches($num, '^[ivxcdml]+$'))">lowerroman</xsl:when>
      <xsl:when test="    ($givenNumeration eq 'upperroman')
                      and (every $num in $nums satisfies matches($num, '^[IVXCDML]+$'))">upperroman</xsl:when>
      <xsl:when test="every $num in $nums satisfies matches($num, '^[0-9]+$')">arabic</xsl:when>
      <xsl:when test="every $num in $nums satisfies matches($num, '^[ivxcdml]+$')">lowerroman</xsl:when>
      <xsl:when test="every $num in $nums satisfies matches($num, '^[IVXCDML]+$')">upperroman</xsl:when>
      <xsl:when test="every $num in $nums satisfies matches($num, '^[a-z]+$')">loweralpha</xsl:when>
      <xsl:when test="every $num in $nums satisfies matches($num, '^[A-Z]+$')">upperalpha</xsl:when>
      <xsl:otherwise>other</xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  

<!-- ================================================================================ -->
<!-- TEMPLATES -->
<!-- ================================================================================ -->

<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="hub:default" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->


  <!-- Dissolve paras with lists into separate block-level elements -->
  <xsl:template  match="para[ *[ local-name() = $hub:list-element-names] ]"  mode="hub:default_" priority="10">
    <xsl:variable name="dissolve" as="element(*)+">
      <xsl:for-each-group select="node()" group-adjacent="exists(self::*[ local-name() = $hub:list-element-names])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:sequence select="current-group()" />
          </xsl:when>
          <xsl:otherwise>
            <para xmlns="http://docbook.org/ns/docbook">
              <xsl:sequence select="@*" />
              <xsl:sequence select="current-group() except *[ local-name() = $hub:list-element-names]" />
            </para>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:apply-templates select="$dissolve" mode="#current" />
  </xsl:template>

  <xsl:template  match="para[ *[ local-name() = $hub:list-element-names] ]" mode="hub:group hub:default" priority="10">
    <xsl:param name="fn" as="element(footnote)?" tunnel="yes"/>
    
    <xsl:variable name="props" select="@*"/>
    <xsl:variable name="dissolve" as="element(*)+">
      <xsl:for-each-group select="node()" group-adjacent="exists(self::*[ local-name() = $hub:list-element-names])">
        <xsl:choose>
          <xsl:when test="current-grouping-key()">
            <xsl:sequence select="current-group()" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="current-group()[normalize-space() or exists(*)]">
              <para xmlns="http://docbook.org/ns/docbook">
                <xsl:sequence select="$props" />
                <xsl:sequence select="current-group() except *[ local-name() = $hub:list-element-names]" />
              </para>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:apply-templates select="$dissolve" mode="#current" />
  </xsl:template>


  <xsl:template  match="*[ local-name() = $hub:list-element-names]"  mode="hub:default">
    <xsl:apply-templates  mode="hub:default">
      <xsl:with-param name="continued-list" as="element(*)?" tunnel="yes" 
                      select="if (listitem[1][@override][not(matches(@override, '^[\( ]?[aA1iI][\.\)]?'))] and tr:isContinuedList(.))
                              then (preceding-sibling::*[ local-name() = $hub:list-element-names]
                                                        [listitem[1][@override][matches(@override, '^[\(]?[aA1iI][\.\)]?')]])[1] 
                              else ()"/>
      <xsl:with-param name="continues" tunnel="yes" 
                      select="if (listitem[1][@override] or (@continuation eq 'continues'))
                                then if (tr:isContinuedList(.))
                                        then true() 
                                     else false()
                              else false()"/>
    </xsl:apply-templates>
  </xsl:template>


  <xsl:template  match="*[ local-name() = $hub:list-element-names]/listitem"  mode="hub:default">
    <xsl:apply-templates  mode="hub:default"/>
  </xsl:template>

  <xsl:template  match="variablelist | varlistentry | varlistentry/listitem"  mode="hub:default">
    <xsl:apply-templates  mode="hub:default"/>
  </xsl:template>

  <xsl:template  match="varlistentry/term | varlistentry/listitem/para | varlistentry/listitem/simpara"  mode="hub:default" priority="2">
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{if (self::term) then 'deflistterm' else 'deflistdef'}"/>
        <xsl:apply-templates select="@css:background-color" mode="props"/>
      </w:pPr>
      <xsl:variable name="rPrContent" as="element(*)*">
      </xsl:variable>
      <xsl:if test="../@xml:id">
        <w:bookmarkStart  w:id="{generate-id(..)}"  w:name="bm_{generate-id(..)}_"/>
      </xsl:if>
      <xsl:apply-templates  select="node()"  mode="#current">
        <xsl:with-param name="rPrContent" select="$rPrContent" tunnel="yes" as="element(*)*"/>
      </xsl:apply-templates>
      <xsl:if test="../@xml:id">
        <w:bookmarkEnd    w:id="{generate-id(..)}"/>
      </xsl:if>
    </w:p>
  </xsl:template>


  <!-- a para within listitem creates a w:p with special pPr-properties -->
  <xsl:template  match="*[ local-name() = $hub:list-element-names]/listitem/para"  mode="hub:default">
    <xsl:param name="continued-list" as="element(*)?" tunnel="yes"/>
    <xsl:param name="continues" tunnel="yes"/>
    <xsl:variable name="ilvl"  select="count( ancestor::*[self::*[ local-name() = $hub:list-element-names]]) - 1" as="xs:integer"/>
    <!-- if list doesn't start here but somewhere else before-->
    <xsl:variable name="numId" select="if (parent::listitem/parent::orderedlist) 
                                       then tr:getLiNumId(., tr:getLastOverrideStart(.)) 
                                       else tr:getLiNumId(., 1)" />
    <!-- §§ should we consider scoping? -->
    <xsl:variable name="in-blockquote" select="if (ancestor::blockquote) then 'Bq' else ''" as="xs:string" />
    <xsl:variable name="continued-list-para" select="if (count(preceding-sibling::para) eq 0) then '' else 'Cont'" as="xs:string" />
    <xsl:variable name="pStyle" select="concat(if ($template-lang = 'de') then 'Listenabsatz' else 'ListParagraph', $in-blockquote, $continued-list-para)"/>
    <xsl:variable name="lvl" as="xs:integer" select="count(ancestor::*[ local-name() = ('itemizedlist','orderedlist')])"/>
    <w:p>
      <w:pPr>
        <w:pStyle w:val="{$pStyle}"/>
        <xsl:choose>
          <xsl:when test="count(preceding-sibling::*)=0">
            <xsl:if test="$continued-list-para eq ''">
              <w:numPr>
                <w:ilvl w:val="{$ilvl}"/>
                <w:numId w:val="{$numId}"/>
              </w:numPr>
              <w:ind w:left="{tr:calculate-li-ind($lvl)}"/>
            </xsl:if>
          </xsl:when>
          <xsl:otherwise>
            <w:numPr>
              <w:ilvl w:val="0"/>
              <w:numId w:val="0"/>
            </w:numPr>
            <w:ind w:left="{tr:calculate-li-ind($lvl)}"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:apply-templates select="@css:background-color" mode="props"/>
      </w:pPr>
      <xsl:apply-templates  select="node()"  mode="hub:default"/>
    </w:p>
  </xsl:template>
  
  <xsl:variable name="ind" as="xs:integer" select="400"/>
  
  <xsl:function name="tr:calculate-li-ind" as="xs:integer">
    <xsl:param name="lvl" as="xs:integer"/>
    <xsl:sequence select="$lvl * $ind"/>
  </xsl:function>


<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->
<!-- mode="numbering" -->
<!-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ -->

  <xsl:template  match="variablelist"  mode="numbering" priority="2"/>

  <xsl:template  match="*[ local-name() = $hub:list-element-names]"  mode="numbering">
    <xsl:variable name="list" as="element()" select="."/>
    <xsl:variable name="ilvl"  select="tr:getIlvl(.)" as="xs:integer"/>
    <xsl:variable name="getOverrideStarts" as="xs:integer*" select="distinct-values(tr:getOverrideStarts(.))"/>
    <xsl:variable name="numbers" as="xs:integer+" select="if (count($getOverrideStarts) gt 0) then $getOverrideStarts else 1"/>
    <xsl:for-each select="$numbers">
    <!-- ~~~~~~~~~~~~~~~~~~~~ w:num ~~~~~~~~~~~~~~~~~~~~ -->
      <w:num>
        <xsl:attribute  name="w:numId"  select="tr:getLiNumId($list, .)"/>
        <w:abstractNumId w:val="{tr:getAbstractNumId($list)}"/>
        <w:lvlOverride w:ilvl="{if(starts-with($list/local-name(), 'biblio')) then 0 else $ilvl}">
          <w:startOverride w:val="{.}" />
        </w:lvlOverride> 
      </w:num>
    </xsl:for-each>
    <xsl:apply-templates  mode="#current"/>
    <!-- ~~~~~~~~~~~~~~~~~~~~ w:abstractNumId ~~~~~~~~~~~~~~~~~~~~ -->
    <!-- Currently we do not want to generate the w:abstractNum-elements referenced by the w:num/w:numId/@val.
         Instead we reference the existing w:abstractNum from the template-numbering.xml-file and adapt the visual appearance using Microbugs Office Word 2007.
         -->
<!--     <w:abstractNum> -->
<!--       <xsl:attribute  name="w:abstractNumId"  select="tr:getAbstractNumId( .)"/> -->
<!--       <\!-\- because we apply a separate w:num/w:abstractNum to each *[ local-name() = $hub:list-element-names] regardless of numbering level, we do need only one <w:lvl> with @w:ilvl="0" -\-> -->
<!--       <w:lvl w:ilvl="0"> -->
<!--         <w:start w:val="1"/> -->
<!--         <w:numFmt w:val="{if ( @numeration eq 'loweralpha') -->
<!--                           then 'lowerLetter' -->
<!--                           else 'decimal'}"/> -->
<!--         <\!-\- §§§ check against source document rendering! -\-> -->
<!--         <w:lvlText w:val="%1)"/> -->
<!--         <w:lvlJc w:val="left"/> -->
<!--       </w:lvl> -->
<!--     </w:abstractNum> -->

  </xsl:template>


  <xsl:template  match="node()"  mode="numbering"  priority="-50">
    <xsl:apply-templates  mode="#current"/>
  </xsl:template>


</xsl:stylesheet>

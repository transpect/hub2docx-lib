<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="2.0" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:saxon="http://saxon.sf.net/"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:tr="http://transpect.io"
  exclude-result-prefixes="w m mml xs saxon tr">
  
  <xsl:include href="fix-mml.xsl"/>
  
  <xsl:output method="xml" encoding="UTF-8" />

  <!-- %%Template: match *
		The catch all template, just passes through -->
  <xsl:template match="*" mode="mml">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>
  
  <xsl:template match="mml:math" mode="mml">
    <xsl:variable name="fix-mml" as="document-node()"><!-- with whatever elements are below mml:math -->
      <xsl:document>
        <xsl:apply-templates select="*" mode="fix-mml"/>
      </xsl:document>
    </xsl:variable>
    <xsl:apply-templates select="$fix-mml" mode="mml"/>
  </xsl:template>

  <!-- %%Template: match *
		Another catch all template, just passes through -->
  <!--<xsl:template match="/" mode="mml">
    <m:oMath>
      <!-\-<xsl:variable name="fix-mml">
        <xsl:apply-templates select="*" mode="fix-mml"/>
      </xsl:variable>-\->
      <xsl:apply-templates select="*" mode="mml"/>
    </m:oMath>
  </xsl:template>-->

  <!-- %%Function: OutputText
		Post processing on the string given and otherwise do a xsl:value-of on it -->
  <xsl:function name="tr:OutputText">
    <xsl:param name="sInput" />
    <!-- 1. Remove any unwanted characters -->
    <!-- 2. Replace any characters as needed -->
    <!--	Replace &#x2A75; <-> ==			 -->
    <xsl:attribute name="xml:space" select="'preserve'"/>
    <!-- Finally, return the last value -->
    <xsl:value-of select="replace(replace($sInput, '[&#x2062;&#x200B;]', ''),'&#x2A75;','==')" />
  </xsl:function>

  <!-- Template that determines whether or the given node ndCur is a token element that doesn't have an mglyph as a child. -->
  <xsl:function name="tr:FNonGlyphToken" as="xs:boolean">
    <xsl:param name="ndCur" />
    <xsl:sequence select="$ndCur/self::mml:mi[not(child::mml:mglyph)] or 
	                        $ndCur/self::mml:mn[not(child::mml:mglyph)] or 
	                        $ndCur/self::mml:mo[not(child::mml:mglyph)] or 
	                        $ndCur/self::mml:ms[not(child::mml:mglyph)] or
                          $ndCur/self::mml:mtext[not(child::mml:mglyph)]"/>
  </xsl:function>

  <!-- Template used to determine if the current token element (ndCur) is the beginning of a run. 
			 A token element is the beginning of if:
			 the count of preceding elements is 0 
			 or 
			 the directory preceding element is not a non-glyph token. -->
  <xsl:function name="tr:FStartOfRun" as="xs:boolean">
    <xsl:param name="ndCur" />
    <!-- https://github.com/transpect/hub2docx-lib/issues/4 -->
    <xsl:param name="first-in-nary-arg" as="element(*)?"/>
    <xsl:sequence select="count($ndCur/preceding-sibling::*)=0 or 
                          ($ndCur is $first-in-nary-arg) (: https://github.com/transpect/hub2docx-lib/issues/4 :) or 
                          not(tr:FNonGlyphToken($ndCur/preceding-sibling::*[1]))"/>
  </xsl:function>

  <!-- Template that determines if ndCur is the argument of an nary expression. 
			 ndCur is the argument of an nary expression if:
			 1.  The preceding sibling is one of the following:  munder, mover, msub, msup, munder, msubsup, munderover
			 and
			 2.  The preceding sibling's child is an nary char as specified by the template "isNary" -->
  <xsl:function name="tr:FIsNaryArgument" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <xsl:choose>
      <!-- https://github.com/transpect/hub2docx-lib/issues/4 -->
      <xsl:when test="$ndCur/parent::mml:mfrac">
        <xsl:sequence select="false()"/>
      </xsl:when>
      <xsl:when test="$ndCur/preceding-sibling::*[1][self::mml:munder or self::mml:mover or self::mml:munderover or
                                                     self::mml:msub or self::mml:msup or self::mml:msubsup] and 
                      tr:isNary($ndCur/preceding-sibling::*[1]/child::*[1])">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="$ndCur/parent::mml:mrow">
        <xsl:sequence select="tr:isNary($ndCur/parent::*) or tr:isNary($ndCur/preceding-sibling::*[1]/child::*[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Template: mml:mrow | mml:mstyle
		 if this row is the next sibling of an n-ary (i.e. any of 
         mover, munder, munderover, msupsub, msup, or msub with 
         the base being an n-ary operator) then ignore this. Otherwise
         pass through -->
  <xsl:template match="mml:mrow|mml:mstyle" mode="mml">
    <xsl:if test="not(tr:FIsNaryArgument(.))">
      <xsl:choose>
        <xsl:when test="tr:FLinearFrac(.)">
          <xsl:sequence select="tr:MakeLinearFraction(.,.)" />
        </xsl:when>
        <xsl:when test="tr:FIsFunc(.)">
          <xsl:sequence select="tr:WriteFunc(.)" />
        </xsl:when>
        <xsl:when test="tr:isNary(child::*[1]) and self::mml:mrow">
          <m:nary>
            <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'mrow','false')"/>
            <m:e>
              <xsl:sequence select="tr:CreateArgProp(.)" />
              <!-- https://github.com/transpect/hub2docx-lib/issues/4 -->
              <xsl:sequence select="tr:NaryHandleMrowMstyle(.,child::*[2],child::*[2])"/>
            </m:e>
          </m:nary>
          <xsl:apply-templates select="child::*[position() gt 2]" mode="#current"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="*" mode="#current"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  <xsl:template match="mml:mi[not(child::mml:mglyph)] | 
	                     mml:mn[not(child::mml:mglyph)] | 
	                     mml:mo[not(child::mml:mglyph)] | 
	                     mml:ms[not(child::mml:mglyph)] |
                       mml:mtext[not(child::mml:mglyph)]" mode="mml">
    <xsl:param name="first-in-nary-arg" as="element(*)?" tunnel="yes"/>
    <xsl:param name="display-in-nary" select="false()"/>
    <!-- tokens with mglyphs as children are tranformed in a different manner than "normal" token elements.  
			 Where normal token elements are token elements that contain only text -->
    <!--In MathML, successive characters that are all part of one string are sometimes listed as separate 
			tags based on their type (identifier (mi), name (mn), operator (mo), quoted (ms), literal text (mtext)), 
			where said tags act to link one another into one logical run.  In order to wrap the text of successive mi's, 
			mn's, and mo's into one m:t, we need to denote where a run begins.  The beginning of a run is the first mi, mn, 
			or mo whose immediately preceding sibling either doesn't exist or is something other than a "normal" mi, mn, mo, 
			ms, or mtext tag-->
    <!-- If this mi/mo/mn/ms . . . is part the numerator or denominator of a linear fraction, then don't collect. -->
    <!-- If this mi/mo/mn/ms . . . is part of the name of a function, then don't collect. -->
    <xsl:variable name="fShouldCollect"
                  select="(not(tr:FLinearFrac(parent::*)) and not(tr:FIsFunc(parent::*))) and 
                          (parent::mml:mrow or parent::mml:mstyle or parent::mml:msqrt or parent::mml:menclose or
					                 parent::mml:math or parent::mml:mphantom or parent::mml:mtd or parent::mml:maction)" />
    <xsl:variable name="maligngroup" select="(preceding-sibling::node()[1]/self::mml:maligngroup/@columnalign = 'left') or 
                                             (preceding-sibling::node()[1]/self::mml:maligngroup/@groupalign = 'left')" as="xs:boolean"/>
    <!--In MathML, the meaning of the different parts that make up mathematical structures, such as a fraction 
			having a numerator and a denominator, is determined by the relative order of those different parts.  
			For instance, In a fraction, the numerator is the first child and the denominator is the second child.  
			To allow for more complex structures, MathML allows one to link a group of mi, mn, and mo's together 
			using the mrow, or mstyle tags.  The mi, mn, and mo's found within any of the above tags are considered 
			one run.  Therefore, if the parent of any mi, mn, or mo is found to be an mrow or mstyle, then the contiguous 
			mi, mn, and mo's will be considered one run.-->
    <xsl:choose>
      <xsl:when test="tr:FStartOfRun(.,$first-in-nary-arg) and tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="$fShouldCollect">
        <xsl:choose>
          <xsl:when test="tr:FStartOfRun(.,$first-in-nary-arg)">
            <!--If this is the beginning of the run, pass all run attributes to CreateRunWithSameProp.-->
            <xsl:sequence select="tr:CreateRunWithSameProp((@mathbackground,@mml:mathbackground)[1],
                                                           (@mathcolor,@mml:mathcolor)[1],
                                                           (@mathvariant,@mml:mathvariant)[1],
                                                           (@color,@mml:color)[1],
                                                           (@font-family,@mml:font-family)[1],
                                                           (@fontsize,@mml:fontsize)[1],
                                                           (@fontstyle,@mml:fontstyle)[1],
                                                           (@fontweight,@mml:fontweight)[1],
                                                           (@mathsize,@mml:mathsize)[1],.,$maligngroup)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!--Only one element will be part of run-->
        <xsl:element name="m:r">
          <!--Create Run Properties based on current node's attributes-->
          <xsl:sequence select="tr:CreateRunProp((@mathbackground,@mml:mathbackground)[1],
                                                 (@mathcolor,@mml:mathcolor)[1],
                                                 (@mathvariant,@mml:mathvariant)[1],
                                                 (@color,@mml:color)[1],
                                                 (@fontsize,@mml:fontsize)[1],
                                                 (@fontstyle,@mml:fontstyle)[1],
                                                 (@fontweight,@mml:fontweight)[1],
                                                 (@mathsize,@mml:mathsize)[1],.,tr:FNor(.),$maligngroup)" />
          <xsl:element name="m:t">
            <xsl:sequence select="tr:OutputText(normalize-space(.))" />
          </xsl:element>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:function name="tr:check-existing-attributes" as="xs:boolean">
    <xsl:param name="context"/>
    <xsl:param name="attribute-names" as="xs:string*"/>
    
    <xsl:sequence select="some $a in $attribute-names 
                          satisfies (exists($context/@*[local-name()=$a]) and not($context/@*[local-name()=$a]=''))"/>
  </xsl:function>

  <!-- %%Function: CreateRunWithSameProp -->
  <xsl:function name="tr:CreateRunWithSameProp">
    <xsl:param name="mathbackground" />
    <xsl:param name="mathcolor" />
    <xsl:param name="mathvariant" />
    <xsl:param name="color" />
    <xsl:param name="font-family" />
    <xsl:param name="fontsize" />
    <xsl:param name="fontstyle" />
    <xsl:param name="fontweight" />
    <xsl:param name="mathsize" />
    <xsl:param name="ndTokenFirst" />
    <xsl:param name="maligngroup" as="xs:boolean"/>
    <!--Given mathcolor, color, mstyle's (ancestor) color, and precedence of said attributes, determine the actual color of the current run-->
    <xsl:variable name="sColorPropCur">
      <xsl:choose>
        <xsl:when test="$mathcolor!=''">
          <xsl:value-of select="$mathcolor" />
        </xsl:when>
        <xsl:when test="$color!=''">
          <xsl:value-of select="$color" />
        </xsl:when>
        <xsl:when test="$ndTokenFirst/ancestor::mml:mstyle[@color][1]/@color!=''">
          <xsl:value-of select="$ndTokenFirst/ancestor::mml:mstyle[@color][1]/@color" />
        </xsl:when>
        <xsl:when test="$ndTokenFirst/ancestor::mml:mstyle[@mml:color][1]/@mml:color!=''">
          <xsl:value-of select="$ndTokenFirst/ancestor::mml:mstyle[@color][1]/@mml:color" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--Given mathsize, and fontsize and precedence of said attributes, determine the actual font size of the current run-->
    <xsl:variable name="sSzCur">
      <xsl:choose>
        <xsl:when test="$mathsize!=''">
          <xsl:value-of select="$mathsize" />
        </xsl:when>
        <xsl:when test="$fontsize!=''">
          <xsl:value-of select="$fontsize" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="''" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <!--Given mathvariant, fontstyle, and fontweight, and precedence of  the attributes, determine the actual font of the current run-->
    <xsl:variable name="sFontCur" select="tr:GetFontCur($ndTokenFirst,$mathvariant,$fontstyle,$fontweight)" />
    <!-- The omml equivalent structure for mml:mtext is an omml run with the run property m:nor (normal) set.
         Therefore, we can only collect mtexts with  other mtext elements.  Suppose the $ndTokenFirst is an 
         mml:mtext, then if any of its following siblings are to be grouped, they must also be mml:text elements.  
         The inverse is also true, suppose the $ndTokenFirst isn't an mml:mtext, then if any of its following siblings 
         are to be grouped with $ndTokenFirst, they can't be mml:mtext elements-->
    <xsl:variable name="fNdTokenFirstIsMText" select="exists($ndTokenFirst/self::mml:mtext)"/>
    <!--In order to determine the length of the run, we will find the number of nodes before the inital node in the run and
			the number of nodes before the first node that DOES NOT belong to the current run.  The number of nodes that will
			be printed is One Less than the difference between the latter and the former-->
    <!--Find index of current node-->
    <!--Find index of next change in run properties.
		    The basic idea is that we want to find the position of the last node in the longest 
				sequence of nodes, starting from ndTokenFirst, that can be grouped into a run.  For
				example, nodes A and B can be grouped together into the same run iff they have the same 
				props.
				To accomplish this grouping, we want to find the next sibling to ndTokenFirst that shouldn't be 
				included in the run of text.  We do this by counting the number of elements that precede the first
				such element that doesn't belong.  The xpath that accomplishes this is below.
						Count the number of siblings the precede the first element after ndTokenFirst that shouldn't belong.
						count($ndTokenFirst/following-sibling::*[ . . . ][1]/preceding-sibling::*)
				Now, the hard part to this is what is represented by the '. . .' above.  This conditional expression is 
				defining what elements *don't* belong to the current run.  The conditions are as follows:
				The element is not a token element (mi, mn, mo, ms, or mtext)
				or
				The token element contains a glyph child (this is handled separately).
				or
				The token is an mtext and the run didn't start with an mtext, or the token isn't an mtext and the run started 
				with an mtext.  We do this check because mtext transforms into an omml m:nor property, and thus, these mtext
				token elements need to be grouped separately from other token elements.
				// We do an or not( . . . ), because it was easier to define what token elements match than how they don't match.
				// Thus, this inner '. . .' defines how token attributes equate to one another.  We add the 'not' outside of to accomplish
				// the goal of the outer '. . .', which is the find the next element that *doesn't* match.
				or not(
				   The background colors match.
					 and
							The current font (sFontCur) matches the mathvariant
							or
							sFontCur is normal and matches the current font characteristics
							or 
							sFontCur is italic and matches the current font characteristics
							or 
							. . .
					 and
					 The font family matches the current font family.
					 ) // end of not().-->
    <xsl:variable name="nndBeforeLim" 
                  select="count($ndTokenFirst/following-sibling::*[(not(self::mml:mi) and not(self::mml:mn) and not(self::mml:mo) and 
                                                                    not(self::mml:ms) and not(self::mml:mtext)) or
					                                                         self::mml:mi[child::mml:mglyph] or self::mml:mn[child::mml:mglyph] or 
					                                                         self::mml:mo[child::mml:mglyph] or self::mml:ms[child::mml:mglyph] or 
					                                                         self::mml:mtext[child::mml:mglyph] or
					                                                         (($fNdTokenFirstIsMText and not(self::mml:mtext)) or 
					                                                          (not($fNdTokenFirstIsMText) and self::mml:mtext)) or  
					                                                         not((($sFontCur=(@mathvariant,@mml:mathvariant) or
							                                                           ($sFontCur='normal' and 
							                                                            ((@mathvariant,@mml:mathvariant)='normal' or 
							                                                             (not(tr:check-existing-attributes(.,('mathvariant'))) and 
							                                                              (((@fontstyle,@mml:fontstyle)='normal' and 
							                                                                not((@fontweight,@mml:fontweight)='bold')) or 
							                                                               (self::mml:mi and string-length(normalize-space(.)) &gt; 1) or 
							                                                               (self::mml:mn and string(number(self::mml:mn/text()))='NaN'))))) or
							                                                           ($sFontCur='italic' and 
							                                                            ((@mathvariant,@mml:mathvariant)='italic' or 
							                                                             (not(tr:check-existing-attributes(.,('mathvariant'))) and 
							                                                              (((@fontstyle,@mml:fontstyle)='italic' and 
							                                                                not((@fontweight,@mml:fontweight)='bold')) or  
															                                               ((self::mml:mn and string(number(self::mml:mn/text()))!='NaN') or 
															                                                self::mml:mo or 
															                                                (self::mml:mi and string-length(normalize-space(.)) &lt;= 1)))))) or
							                                                           ($sFontCur='bold' and 
							                                                            ((@mathvariant,@mml:mathvariant)='bold' or 
							                                                             (not(tr:check-existing-attributes(.,('mathvariant'))) and 
							                                                              (((@fontweight,@mml:fontweight)='bold' and 
							                                                                ((@fontstyle,@mml:fontstyle)='normal' or 
							                                                                 (self::mml:mi and string-length(normalize-space(.)) &lt;= 1))))))) or
							                                                           (($sFontCur=('bi','bold-italic')) and 
							                                                            ((@mathvariant,@mml:mathvariant)='bold-italic' or 
							                                                             (not(tr:check-existing-attributes(.,('mathvariant'))) and 
							                                                              (((@fontweight,@mml:fontweight)='bold' and 
							                                                                (@fontstyle,@mml:fontstyle)='italic') or 
							                                                               ((@fontweight,@mml:fontweight)='bold' and 
							                                                                (self::mml:mn or 
							                                                                 self::mml:mo or 
							                                                                 (self::mml:mi and string-length(normalize-space(.)) &lt;= 1))))))) or
                                                                         (($sFontCur='' and 
                                                                           (not(tr:check-existing-attributes(.,
                                                                                                             ('mathvariant', 'fontstyle', 
                                                                                                              'fontweight'))) or 
                                                                            (@mathvariant,@mml:mathvariant)='italic' or 
                                                                            (not(tr:check-existing-attributes(.,('mathvariant'))) and 
                                                                             (((@fontweight,@mml:fontweight)='normal' and 
                                                                               (@fontstyle,@mml:fontstyle)='italic') or
                                                                              not(tr:check-existing-attributes(.,('fontweight'))) and 
		                                                                          (@fontstyle,@mml:fontstyle)='italic' or
		                                                                          not(tr:check-existing-attributes(.,('fontweight','fontstyle')))))))) or
                                                                         ($sFontCur='normal' and 
                                                                          ((self::mml:mi and 
                                                                            not(tr:check-existing-attributes(.,
                                                                                                             ('mathvariant','fontstyle',
                                                                                                              'fontweight'))) and 
                                                                            (string-length(normalize-space(.)) &gt; 1)) or 
                                                                           ((self::mml:ms or self::mml:mtext) and 
                                                                            not(tr:check-existing-attributes(.,
                                                                                                             ('mathvariant','fontstyle',
                                                                                                              'fontweight'))))))) and
                                                                        ($font-family = (@font-family,@mml:font-family) or 
                                                                         (($font-family='' or not($font-family)) and 
                                                                          not(tr:check-existing-attributes(.,('font-family')))))))]
                                                                  [1]/preceding-sibling::*)" />
    <xsl:variable name="cndRun" select="$nndBeforeLim - count($ndTokenFirst/preceding-sibling::*)" />
    <!--Contiguous groups of like-property mi, mn, and mo's are separated by non- mi, mn, mo tags, or mi,mn, or mo
			tags with different properties.  nndBeforeLim is the number of nodes before the next tag which separates contiguous 
			groups of like-property mi, mn, and mo's.  Knowing this delimiting tag allows for the aggregation of the correct 
			number of mi, mn, and mo tags.-->
    <xsl:element name="m:r">
      <!--The beginning and ending of the current run has been established. Now we should open a run element-->
      <xsl:choose>
        <!--If cndRun > 0, then there is a following diffrent prop, or non- Token, 
						although there may or may not have been a preceding different prop, or non-
						Token-->
        <xsl:when test="$cndRun &gt; 0">
          <xsl:sequence select="tr:CreateRunProp($mathbackground,$mathcolor,$mathvariant,$color,$fontsize,$fontstyle,$fontweight,
                                                 $mathsize,$ndTokenFirst,tr:FNor($ndTokenFirst),$maligngroup)" />
          <xsl:element name="m:t">
            <xsl:variable name="sInput-param">
              <xsl:choose>
                <xsl:when test="$ndTokenFirst/self::mml:ms">
                  <xsl:sequence select="tr:OutputMs($ndTokenFirst)"/>
                </xsl:when>
                <xsl:when test="$ndTokenFirst/self::mml:mtext">
                  <xsl:value-of select="string($ndTokenFirst)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="normalize-space($ndTokenFirst)" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:for-each select="$ndTokenFirst/following-sibling::*[position() &lt; $cndRun]">
                <xsl:choose>
                  <xsl:when test="self::mml:ms">
                    <xsl:sequence select="tr:OutputMs(.)"/>
                  </xsl:when>
                  <xsl:when test="self::mml:mtext">
                    <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space(.)" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="tr:OutputText($sInput-param)"/>
          </xsl:element>
        </xsl:when>
        <xsl:otherwise>
          <!--if cndRun lt;= 0, then iNextNonToken = 0, and iPrecNonToken gt;= 0.  In either case, b/c there is no next different property or non-Token (which is implied by the nndBeforeLast being equal to 0) you can put all the remaining mi, mn, and mo's into one group.-->
          <xsl:sequence select="tr:CreateRunProp($mathbackground,$mathcolor,$mathvariant,$color,$fontsize,$fontstyle,$fontweight,
                                                 $mathsize,$ndTokenFirst,tr:FNor($ndTokenFirst),$maligngroup)" />
          <xsl:element name="m:t">
            <!--Create the Run, first output current, then in a for-each, because all the following siblings are mn, mi, and mo's that conform to the run's properties, group them together-->
            <xsl:variable name="sInput-param">
              <xsl:choose>
                <xsl:when test="$ndTokenFirst/self::mml:ms">
                  <xsl:sequence select="tr:OutputMs($ndTokenFirst)"/>
                </xsl:when>
                <xsl:when test="$ndTokenFirst/self::mml:mtext">
                  <xsl:value-of select="string($ndTokenFirst)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="normalize-space($ndTokenFirst)" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:for-each select="$ndTokenFirst/following-sibling::*[self::mml:mi or self::mml:mn or self::mml:mo or 
                                                                       self::mml:ms or self::mml:mtext]">
                <xsl:choose>
                  <xsl:when test="self::mml:ms">
                    <xsl:sequence select="tr:OutputMs(.)"/>
                  </xsl:when>
                  <xsl:when test="self::mml:mtext">
                    <xsl:value-of select="."/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space(.)" />
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="tr:OutputText($sInput-param)"/>
          </xsl:element>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
    <!--The run was terminated by an mi, mn, mo, ms, or mtext with different properties, 
				therefore, call-template CreateRunWithSameProp, using cndRun+1 node as new start node-->
    <xsl:if test="$nndBeforeLim!=0 and 
                  ($ndTokenFirst/following-sibling::*[$cndRun]/self::mml:mi or 
					         $ndTokenFirst/following-sibling::*[$cndRun]/self::mml:mn or
					         $ndTokenFirst/following-sibling::*[$cndRun]/self::mml:mo or
					         $ndTokenFirst/following-sibling::*[$cndRun]/self::mml:ms or
                   $ndTokenFirst/following-sibling::*[$cndRun]/self::mml:mtext) and 
                  count($ndTokenFirst/following-sibling::*[$cndRun]/mml:mglyph) = 0">
      <xsl:sequence select="tr:CreateRunWithSameProp(($ndTokenFirst/following-sibling::*[$cndRun]/@mathbackground,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:mathbackground)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@mathcolor,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:mathcolor)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@mathvariant,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:mathvariant)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@color,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:color)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@font-family,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:font-family)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@fontsize,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:fontsize)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@fontstyle,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:fontstyle)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@fontweight,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:fontweight)[1],
                                                     ($ndTokenFirst/following-sibling::*[$cndRun]/@mathsize,
                                                      $ndTokenFirst/following-sibling::*[$cndRun]/@mml:mathsize)[1],
                                                     $ndTokenFirst/following-sibling::*[$cndRun],
                                                     $maligngroup)" />
    </xsl:if>
  </xsl:function>

  <!-- %%Function: FNor
				 Given the context of ndCur, determine if ndCur should be omml's normal style. -->
  <xsl:function name="tr:FNor" as="xs:boolean">
    <xsl:param name="ndCur" />
      <!-- Is the current node an mml:mtext, or if this is an mglyph whose parent is an mml:mtext. -->
      <xsl:sequence select="$ndCur/self::mml:mtext or ($ndCur/self::mml:mglyph and $ndCur/parent::mml:mtext)"/>
  </xsl:function>

  <!-- %%Function: CreateRunProp -->
  <xsl:function name="tr:CreateRunProp">
    <xsl:param name="mathbackground" />
    <xsl:param name="mathcolor" />
    <xsl:param name="mathvariant" />
    <xsl:param name="color" />
    <xsl:param name="fontsize" />
    <xsl:param name="fontstyle" />
    <xsl:param name="fontweight" />
    <xsl:param name="mathsize" />
    <xsl:param name="ndCur" />
    <xsl:param name="fNor" as="xs:boolean"/>
    <xsl:param name="maligngroup" as="xs:boolean"/>
    <xsl:variable name="sFontCur" select="tr:GetFontCur($ndCur,$mathvariant,$fontstyle,$fontweight)" />
    <xsl:if test="$fNor or ($sFontCur!='italic' and $sFontCur!='') or $mathcolor!='' or $mathbackground!='' or $fontweight='normal'">
      <xsl:variable name="w-rPr" as="element(w:rPr)">
        <w:rPr>
          <xsl:choose>
            <xsl:when test="$sFontCur = ('bi', 'bold-italic')">
              <w:b/>
              <w:i/>
            </xsl:when>
            <xsl:when test="$sFontCur = 'bold'">
              <w:b/>
            </xsl:when>
            <xsl:when test="$sFontCur = 'italic'">
              <w:i/>
            </xsl:when>
            <xsl:when test="$fontweight='normal'">
              <w:b w:val="0"/>
            </xsl:when>
          </xsl:choose>
          <xsl:if test="$mathcolor!=''">
            <w:color w:val="{$mathcolor}"/>
          </xsl:if>
          <xsl:if test="$mathbackground!=''">
            <w:highlight w:val="{tr:highlight-color($mathbackground)}"/>
          </xsl:if>
        </w:rPr>
      </xsl:variable>
      <xsl:if test="$w-rPr/node()">
        <xsl:sequence select="$w-rPr"/>
      </xsl:if>
    </xsl:if>
    <xsl:sequence select="tr:CreateMathRPR($mathvariant,$fontstyle,$fontweight,$ndCur,$fNor,$sFontCur,$maligngroup)"/>
  </xsl:function>
  
  <xsl:function name="tr:highlight-color" as="xs:string?" >
    <xsl:param name="val" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="matches($val,'^(#?00FFFF|aqua|cyan)$','i')">
        <xsl:sequence select="'cyan'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?00008[0B]|navy|darkBlue)$','i')">
        <xsl:sequence select="'darkBlue'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?008[0B]8[0B]|teal|darkCyan)$','i')">
        <xsl:sequence select="'darkCyan'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?(808080|A9A9A9)|gray|darkGray)$','i')">
        <xsl:sequence select="'darkGray'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?00(80|64)00|green|darkGreen)$','i')">
        <xsl:sequence select="'darkGreen'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?800080|purple|darkMagenta)$','i')">
        <xsl:sequence select="'darkMagenta'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?8[0B]0000|maroon|darkRed)$','i')">
        <xsl:sequence select="'darkRed'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?808000|olive|darkYellow)$','i')">
        <xsl:sequence select="'darkYellow'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?00FF00|lime|green)$','i')">
        <xsl:sequence select="'green'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?(C0C0C0|D3D3D3)|silver|lightGray)$','i')">
        <xsl:sequence select="'lightGray'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?FF00FF|fuchsia|magenta)$','i')">
        <xsl:sequence select="'magenta'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?FFFF00|yellow)$','i')">
        <xsl:sequence select="'yellow'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?0000FF|blue)$','i')">
        <xsl:sequence select="'blue'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?FF0000|red)$','i')">
        <xsl:sequence select="'red'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?000000|black)$','i')">
        <xsl:sequence select="'black'" />
      </xsl:when>
      <xsl:when test="matches($val,'^(#?FFFFFF|white)$','i')">
        <xsl:sequence select="'white'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="'none'" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Template: CreateMathRPR -->
  <xsl:function name="tr:CreateMathRPR" as="element(m:rPr)?">
    <xsl:param name="mathvariant" />
    <xsl:param name="fontstyle" />
    <xsl:param name="fontweight" />
    <xsl:param name="ndCur" />
    <xsl:param name="fNor" as="xs:boolean"/>
    <xsl:param name="sFontCur"/>
    <xsl:param name="maligngroup" as="xs:boolean"/>
    <xsl:if test="$fNor or ($sFontCur!='italic' and $sFontCur!='') or $maligngroup">
      <xsl:element name="m:rPr">
        <xsl:if test="$maligngroup">
          <m:aln/>
        </xsl:if>
        <xsl:if test="$fNor">
          <m:nor />
        </xsl:if>
        <xsl:sequence select="tr:CreateMathScrStyProp($sFontCur,$fNor)" />
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <!-- %%Function: GetFontCur -->
  <xsl:function name="tr:GetFontCur" as="xs:string">
    <xsl:param name="ndCur" />
    <xsl:param name="mathvariant" as="xs:string?"/>
    <xsl:param name="fontstyle" />
    <xsl:param name="fontweight" />
    <xsl:choose>
      <xsl:when test="$mathvariant!=''">
        <xsl:value-of select="$mathvariant" />
      </xsl:when>
      <xsl:when test="not($ndCur)">
        <xsl:value-of select="'italic'" />
      </xsl:when>
      <xsl:when test="($ndCur/self::mml:mi and (string-length(normalize-space($ndCur)) &lt;= 1)) or 
                      ($ndCur/self::mml:mn and string(number($ndCur/text()))!='NaN') or 
                      $ndCur/self::mml:mo">
        <!-- The default for the above three cases is fontstyle=italic fontweight=normal.-->
        <xsl:choose>
          <xsl:when test="$fontstyle='normal' and $fontweight='bold'">
            <!-- In omml, a sty of 'b' (which is what bold is translated into) implies a normal fontstyle -->
            <xsl:value-of select="'bold'" />
          </xsl:when>
          <xsl:when test="$fontstyle='normal'">
            <xsl:value-of select="'normal'" />
          </xsl:when>
          <xsl:when test="$fontweight='bold'">
            <xsl:value-of select="'bi'" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'italic'" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!--Default is fontweight = 'normal' and fontstyle='normal'-->
        <xsl:choose>
          <xsl:when test="$fontstyle='italic' and $fontweight='bold'">
            <xsl:value-of select="'bi'" />
          </xsl:when>
          <xsl:when test="$fontstyle='italic'">
            <xsl:value-of select="'italic'" />
          </xsl:when>
          <xsl:when test="$fontweight='bold'">
            <xsl:value-of select="'bold'" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="'normal'" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Function: CreateMathScrStyProp -->
  <xsl:function name="tr:CreateMathScrStyProp" as="element()*">
    <xsl:param name="font" as="xs:string"/>
    <xsl:param name="fNor" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="$font='normal' and not($fNor)">
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">p</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='bold'">
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">b</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='italic'"/>
      <xsl:when test="$font='script'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">script</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='bold-script'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">script</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">b</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='double-struck'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">double-struck</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">p</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='fraktur'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">fraktur</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">p</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='bold-fraktur'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">fraktur</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">b</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='sans-serif'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">sans-serif</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">p</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='bold-sans-serif'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">sans-serif</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">b</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='sans-serif-italic'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">sans-serif</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='sans-serif-bold-italic'">
        <xsl:element name="m:scr">
          <xsl:attribute name="m:val">sans-serif</xsl:attribute>
        </xsl:element>
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">bi</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font='monospace'" />
      <!-- We can't do monospace, so leave empty -->
      <xsl:when test="$font='bold'">
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">b</xsl:attribute>
        </xsl:element>
      </xsl:when>
      <xsl:when test="$font=('bi','bold-italic')">
        <xsl:element name="m:sty">
          <xsl:attribute name="m:val">bi</xsl:attribute>
        </xsl:element>
      </xsl:when>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:FBar" as="xs:boolean">
    <xsl:param name="sLineThickness" />
    <xsl:sequence select="string-length($sLineThickness)=0 or 
                          lower-case($sLineThickness)=('thin','medium','thick') or
                          matches(lower-case($sLineThickness), '[1-9]')"/>
  </xsl:function>

  <!-- %%Template: match mfrac -->
  <xsl:template match="mml:mfrac" mode="mml">
    <xsl:element name="m:f">
      <xsl:element name="m:fPr">
        <xsl:element name="m:type">
          <xsl:attribute name="m:val">
            <xsl:choose>
              <xsl:when test="not(tr:FBar((@linethickness,@mml:linethickness)[1]))">noBar</xsl:when>
              <xsl:when test="(@bevelled,@mml:bevelled)='true'">skw</xsl:when>
              <xsl:otherwise>bar</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
        </xsl:element>
      </xsl:element>
      <xsl:element name="m:num">
        <xsl:sequence select="tr:CreateArgProp(.)" />
        <xsl:apply-templates select="child::*[1]" mode="#current"/>
      </xsl:element>
      <xsl:element name="m:den">
        <xsl:sequence select="tr:CreateArgProp(.)" />
        <xsl:apply-templates select="child::*[2]" mode="#current"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- %%Template: match menclose msqrt -->
  <xsl:template match="mml:menclose | mml:msqrt" mode="mml">
    <xsl:variable name="sLowerCaseNotation" select="lower-case((@notation,@mml:notation)[1])"/>
    <xsl:choose>
      <!-- Take care of default -->
      <xsl:when test="$sLowerCaseNotation=('radical','') 
                      or not($sLowerCaseNotation) 
                      or self::mml:msqrt">
        <xsl:element name="m:rad">
          <xsl:element name="m:radPr">
            <xsl:element name="m:degHide">
              <xsl:attribute name="m:val">on</xsl:attribute>
            </xsl:element>
          </xsl:element>
          <xsl:element name="m:deg">
            <xsl:sequence select="tr:CreateArgProp(.)" />
          </xsl:element>
          <xsl:element name="m:e">
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="*" mode="#current" />
          </xsl:element>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$sLowerCaseNotation=('actuarial','longdiv')" />
          <xsl:otherwise>
            <xsl:element name="m:borderBox">
              <!-- Dealing with more complex notation attribute -->
              <xsl:variable name="fBox" select="xs:boolean(contains($sLowerCaseNotation, 'box')
                                  or contains($sLowerCaseNotation, 'circle')
                                  or contains($sLowerCaseNotation, 'roundedbox'))"/>
              <xsl:variable name="fTop" select="xs:boolean(contains($sLowerCaseNotation, 'top'))"/>
              <xsl:variable name="fBot" select="xs:boolean(contains($sLowerCaseNotation, 'bottom'))"/>
              <xsl:variable name="fLeft" select="xs:boolean(contains($sLowerCaseNotation, 'left'))"/>
              <xsl:variable name="fRight" select="xs:boolean(contains($sLowerCaseNotation, 'right'))"/>
              <xsl:variable name="fStrikeH" select="xs:boolean(contains($sLowerCaseNotation, 'horizontalstrike'))"/>
              <xsl:variable name="fStrikeV" select="xs:boolean(contains($sLowerCaseNotation, 'verticalstrike'))"/>
              <xsl:variable name="fStrikeBLTR" select="xs:boolean(contains($sLowerCaseNotation, 'updiagonalstrike'))"/>
              <xsl:variable name="fStrikeTLBR" select="xs:boolean(contains($sLowerCaseNotation, 'downdiagonalstrike'))"/>
              <!-- Should we create borderBoxPr? 
                   We should if the enclosure isn't Word's default, which is a plain box -->
              <xsl:if test="$fStrikeH or $fStrikeV or $fStrikeBLTR or $fStrikeTLBR or 
                            (not($fBox) and not($fTop and $fBot and $fLeft and $fRight))">
                <xsl:element name="m:borderBoxPr">
                  <xsl:if test="not($fBox)">
                    <xsl:if test="not($fTop)">
                      <xsl:element name="m:hideTop">
                        <xsl:attribute name="m:val">on</xsl:attribute>
                      </xsl:element>
                    </xsl:if>
                    <xsl:if test="not($fBot)">
                      <xsl:element name="m:hideBot">
                        <xsl:attribute name="m:val">on</xsl:attribute>
                      </xsl:element>
                    </xsl:if>
                    <xsl:if test="not($fLeft)">
                      <xsl:element name="m:hideLeft">
                        <xsl:attribute name="m:val">on</xsl:attribute>
                      </xsl:element>
                    </xsl:if>
                    <xsl:if test="not($fRight)">
                      <xsl:element name="m:hideRight">
                        <xsl:attribute name="m:val">on</xsl:attribute>
                      </xsl:element>
                    </xsl:if>
                  </xsl:if>
                  <xsl:if test="$fStrikeH">
                    <xsl:element name="m:strikeH">
                      <xsl:attribute name="m:val">on</xsl:attribute>
                    </xsl:element>
                  </xsl:if>
                  <xsl:if test="$fStrikeV">
                    <xsl:element name="m:strikeV">
                      <xsl:attribute name="m:val">on</xsl:attribute>
                    </xsl:element>
                  </xsl:if>
                  <xsl:if test="$fStrikeBLTR">
                    <xsl:element name="m:strikeBLTR">
                      <xsl:attribute name="m:val">on</xsl:attribute>
                    </xsl:element>
                  </xsl:if>
                  <xsl:if test="$fStrikeTLBR">
                    <xsl:element name="m:strikeTLBR">
                      <xsl:attribute name="m:val">on</xsl:attribute>
                    </xsl:element>
                  </xsl:if>
                </xsl:element>
              </xsl:if>
              <xsl:element name="m:e">
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="*" mode="#current" />
              </xsl:element>
            </xsl:element>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Function: CreateArgProp -->
  <xsl:function name="tr:CreateArgProp" as="element(m:argPr)?">
    <xsl:param name="context" />
    <xsl:if test="not(count($context/ancestor-or-self::mml:mstyle[@scriptlevel=('0','1','2')])=0) or 
                  not(count($context/ancestor-or-self::mml:mstyle[@mml:scriptlevel=('0','1','2')])=0)">
      <xsl:element name="m:argPr">
        <xsl:element name="m:scrLvl">
          <xsl:attribute name="m:val" select="($context/ancestor-or-self::mml:mstyle[@scriptlevel][1]/@scriptlevel,
                                               $context/ancestor-or-self::mml:mstyle[@scriptlevel][1]/@mml:scriptlevel)[1]"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <!-- %%Template: match mroot -->
  <xsl:template match="mml:mroot" mode="mml">
    <xsl:element name="m:rad">
      <xsl:element name="m:radPr">
        <xsl:element name="m:degHide">
          <xsl:attribute name="m:val" select="(child::*[2][exists(descendant-or-self::*[not(self::mml:mrow)])]/'off','on')[1]"/>
        </xsl:element>
      </xsl:element>
      <xsl:element name="m:deg">
        <xsl:sequence select="tr:CreateArgProp(.)" />
        <xsl:apply-templates select="child::*[2]" mode="#current" />
      </xsl:element>
      <xsl:element name="m:e">
        <xsl:sequence select="tr:CreateArgProp(.)" />
        <xsl:apply-templates select="child::*[1]" mode="#current" />
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- MathML has no concept of a linear fraction.  When transforming a linear fraction from Omml to MathML, we create the following MathML:
       <mml:mrow>
         <mml:mrow>
            // numerator
         </mml:mrow>
         <mml:mo>/</mml:mo>
         <mml:mrow>
            // denominator
         </mml:mrow>
       </mml:mrow>
       This function looks for four things:
          1.  ndCur is an mml:mrow
          2.  ndCur has three children
          3.  The second child is an <mml:mo>
          4.  The second child's text is '/' -->
  <xsl:function name="tr:FLinearFrac" as="xs:boolean">
    <xsl:param name="ndCur"/>
      <!-- I spy a linear fraction -->
      <xsl:sequence select="$ndCur/self::mml:mrow and 
                            count($ndCur/*)=3 and 
                            $ndCur/*[2][self::mml:mo] and 
                            normalize-space($ndCur/*[2])='/'"/>
  </xsl:function>

  <!-- Though presentation mathml can certainly typeset any generic function with the
	     appropriate function operator spacing, presentation MathML has no concept of 
			 a function structure like omml does.  In order to preserve the omml <func> 
			 element, we must establish how an omml <func> element looks in mml.  This 
			 is shown below:
       <mml:mrow>
         <mml:mrow>
            // function name
         </mml:mrow>
         <mml:mo>&#x02061;</mml:mo>
         <mml:mrow>
            // function argument
         </mml:mrow>
       </mml:mrow>
       This function looks for six things to be true:
					1.  ndCur is an mml:mrow
					2.  ndCur has three children
					3.  The first child is an <mml:mrow>
					4.  The second child is an <mml:mo>
					5.  The third child is an <mml:mrow>
					6.  The second child's text is '&#x02061;' -->
  <xsl:function name="tr:FIsFunc" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <!-- Is this an omml function -->
    <xsl:sequence select="count($ndCur/*)=3 and 
                          $ndCur/self::mml:mrow and 
                          $ndCur/*[2][self::mml:mo] and 
                          normalize-space($ndCur/*[2])='&#x02061;'"/>
  </xsl:function>

  <!-- Given the node of the linear fraction's parent mrow, make a linear fraction -->
  <xsl:function name="tr:MakeLinearFraction" as="element(m:f)">
    <xsl:param name="ndCur" />
    <xsl:param name="context"/>
    <xsl:element name="m:f">
      <xsl:element name="m:fPr">
        <xsl:element name="m:type">
          <xsl:attribute name="m:val">lin</xsl:attribute>
        </xsl:element>
      </xsl:element>
      <xsl:element name="m:num">
        <xsl:sequence select="tr:CreateArgProp($context)" />
        <xsl:apply-templates select="$ndCur/*[1]" mode="mml" />
      </xsl:element>
      <xsl:element name="m:den">
        <xsl:sequence select="tr:CreateArgProp($context)" />
        <xsl:apply-templates select="$ndCur/*[3]" mode="mml" />
      </xsl:element>
    </xsl:element>
  </xsl:function>

  <!-- Given the node of the function's parent mrow, make an omml function -->
  <xsl:function name="tr:WriteFunc" as="element(m:func)">
    <xsl:param name="ndCur"/>
    <xsl:element name="m:func">
      <xsl:element name="m:fName">
        <xsl:apply-templates select="$ndCur/child::*[1]" mode="mml" />
      </xsl:element>
      <xsl:element name="m:e">
        <xsl:apply-templates select="$ndCur/child::*[3]" mode="mml" />
      </xsl:element>
    </xsl:element>
  </xsl:function>

  <!-- MathML doesn't have the concept of nAry structures.  The best approximation to these is to have some under/over or sub/sup followed by an mrow or mstyle.
       In the case that we've come across some under/over or sub/sup that contains an nAry operator, this function handles the following sibling to the nAry structure.
       If the following sibling is:
          mml:mstyle, then apply templates to the children of this mml:mstyle
          mml:mrow, determine if this mrow is a linear fraction 
          (see comments for FlinearFrac template).
              If so, make an Omml linear fraction.
              If not, apply templates as was done for mml:mstyle. -->
  <xsl:function name="tr:NaryHandleMrowMstyle">
    <xsl:param name="context"/>
    <xsl:param name="ndCur"/>
    <xsl:param name="first-in-nary-arg"/>
    <!-- if the next sibling is an mrow, pull it in by  doing whatever we would have done to its children. 
				 The mrow itself will be skipped, see template above. -->
    <xsl:choose>
      <xsl:when test="$ndCur[self::mml:mrow]">
        <!-- Check for linear fraction -->
        <xsl:choose>
          <xsl:when test="tr:FLinearFrac($ndCur)">
            <xsl:sequence select="tr:MakeLinearFraction($ndCur,$context)" />
          </xsl:when>
          <xsl:when test="tr:FIsFunc($context)">
            <xsl:sequence select="tr:WriteFunc($context)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="if (tr:isNary($ndCur/*[1])) then $ndCur else $ndCur/*" mode="mml">
              <xsl:with-param name="display-in-nary" select="true()"/>
              <xsl:with-param name="first-in-nary-arg" select="$first-in-nary-arg" tunnel="yes"/>
            </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$ndCur[self::mml:mstyle]">
        <xsl:apply-templates select="$ndCur/*" mode="mml" >
          <xsl:with-param name="display-in-nary" select="true()"/>
          <xsl:with-param name="first-in-nary-arg" select="$first-in-nary-arg" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:when>
      <xsl:otherwise>
        <!-- https://github.com/transpect/hub2docx-lib/issues/4 -->
        <xsl:apply-templates select="$ndCur" mode="mml" >
          <xsl:with-param name="display-in-nary" select="true()"/>
          <xsl:with-param name="first-in-nary-arg" select="$first-in-nary-arg" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- MathML munder/mover can represent several Omml constructs (m:bar, m:limLow, m:limUpp, m:acc, m:groupChr, etc.).  
       The following functions (FIsBar, FIsAcc, and FIsGroupChr) are used to determine which of these Omml constructs an munder/mover should be translated into. -->
  <!-- Note:  ndCur should only be an munder/mover MathML element.
       ndCur should be interpretted as an m:bar if
          1)  its respective accent attribute is not true
          2)  its second child is an mml:mo
          3)  the character of the mml:mo is the correct under/over bar. -->
  <xsl:function name="tr:FIsBar" as="xs:boolean">
    <xsl:param name="ndCur" />
    <xsl:choose>
      <!-- The script is unaccented and the second child is an mo -->
      <xsl:when test="$ndCur/child::*[2]/self::mml:mo">
          <!-- Should we write an underbar? -->
          <!-- Should we write an overbar? -->
        <xsl:sequence select="if ($ndCur[self::mml:munder]) 
                              then ($ndCur/@accentunder='true' or $ndCur/child::*[2] = ('&#x0332;','&#x005F;','&#x0305;','&#x00AF;'))
                              else ($ndCur/@accentover='true' or $ndCur/child::*[2] = ('&#x0332;','&#x005F;','&#x0305;','&#x00AF;'))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Note:  ndCur should only be an mover MathML element.
       ndCur should be interpretted as an m:acc if
          1)  its accent attribute is true
          2)  its second child is an mml:mo
          3)  there is only zero or one character in the mml:mo -->
  <xsl:function name="tr:FIsAcc" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <xsl:variable name="sLowerCaseMoAccent">
      <xsl:if test="$ndCur/child::*[2]/self::mml:mo and $ndCur/child::*[2][@accent or @mml:accent]">
        <xsl:value-of select="lower-case(($ndCur/child::*[2]/@accent,$ndCur/child::*[2]/@mml:accent)[1])"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="fAccent" select="xs:boolean($sLowerCaseMoAccent='true' or 
                                                    ($sLowerCaseMoAccent='' and 
                                                     lower-case(($ndCur/@accent,$ndCur/@mml:accent)[1])='true'))"/>
    <!-- The script is accented and the second child is an mo -->
    <!-- There is only one operator, this is a valid Omml accent! -->
    <!-- More than one accented operator.  This isn't a valid omml accent -->
    <!-- Not accented, not an operator, or both, but in any case, this is not an Omml accent. -->
    <xsl:sequence select="if ($fAccent and $ndCur/child::*[2]/self::mml:mo) 
                          then string-length(xs:string($ndCur/child::*[2])) &lt;= 1 
                          else false()"/>
  </xsl:function>

  <!-- Is ndCur a groupChr? 
			 ndCur is a groupChr if:
				 1.  The accent is false (note:  accent attribute for munder is accentunder). 
				 2.  ndCur is an munder or mover.
				 3.  ndCur has two children
				 4.  Of these two children, one is an mml:mo and the other is an mml:mrow
				 5.  The number of characters in the mml:mo is 1.
			 If all of the above are true, then return 1, else return 0. -->
  <xsl:function name="tr:FIsGroupChr" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <xsl:variable name="sLowerCaseAccent">
      <xsl:choose>
        <xsl:when test="exists($ndCur[self::mml:munder])">
          <xsl:value-of select="lower-case(($ndCur/@accentunder,$ndCur/@mml:accentunder)[1])"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(($ndCur/@accent,$ndCur/@mml:accent)[1])"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$sLowerCaseAccent='false' and 
                      $ndCur[self::mml:munder or self::mml:mover] and 
                      count($ndCur/child::*)=2 and 
                      (($ndCur/child::*[1][self::mml:mrow] and $ndCur/child::*[2][self::mml:mo]) or 
                       ($ndCur/child::*[1][self::mml:mo] and $ndCur/child::*[2][self::mml:mrow]))">
        <xsl:sequence select="string-length(xs:string($ndCur/child::mml:mo)) &lt;= 1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Template: match munder -->
  <xsl:template match="mml:munder" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'munder',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current" />
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <!-- Should this munder be interpreted as an OMML m:bar? -->
        <xsl:choose>
          <xsl:when test="tr:FIsBar(.)">
            <m:bar>
              <m:barPr>
                <m:pos m:val="bot" />
              </m:barPr>
              <m:e>
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current" />
              </m:e>
            </m:bar>
          </xsl:when>
          <xsl:otherwise>
            <!-- It isn't an integral or underbar, is this a groupChr? -->
            <xsl:choose>
              <xsl:when test="tr:FIsGroupChr(.)">
                <xsl:element name="m:groupChr">
                  <xsl:sequence select="tr:CreateGroupChrPr('mml:mo',if (child::*[1][self::mml:mrow]) then 'bot' else 'top','top')"/>
                  <xsl:element name="m:e">
                    <xsl:apply-templates select="mml:mrow" mode="#current" />
                  </xsl:element>
                </xsl:element>
              </xsl:when>
              <xsl:otherwise>
                <!-- Generic munder -->
                <xsl:element name="m:limLow">
                  <xsl:element name="m:e">
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[1]" mode="#current" />
                  </xsl:element>
                  <xsl:element name="m:lim">
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[2]" mode="#current" />
                  </xsl:element>
                </xsl:element>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Given the values for chr, pos, and vertJc, create an omml groupChr's groupChrPr -->
  <xsl:function name="tr:CreateGroupChrPr" as="element(m:groupChrPr)">
    <xsl:param name="chr"/>
    <xsl:param name="pos" />
    <xsl:param name="vertJc" />
    <xsl:element name="m:groupChrPr">
      <xsl:element name="m:chr">
        <xsl:attribute name="m:val" select="$chr"/>
      </xsl:element>
      <xsl:element name="m:pos">
        <xsl:attribute name="m:val" select="$pos"/>
      </xsl:element>
      <xsl:element name="m:vertJc">
        <xsl:attribute name="m:val" select="$vertJc"/>
      </xsl:element>
    </xsl:element>
  </xsl:function>

  <!-- Convert a non-combining character into its upper combining couterpart.
      { Non-combining, Upper-combining }
      {U+02D8, U+0306}, // BREVE
      {U+00B8, U+0312}, // CEDILLA
      {U+0060, U+0300}, // GRAVE ACCENT
      {U+002D, U+0305}, // HYPHEN-MINUS/OVERLINE
      {U+2212, U+0305}, // MINUS SIGN/OVERLINE
      {U+002E, U+0305}, // FULL STOP/DOT ABOVE
      {U+02D9, U+0307}, // DOT ABOVE
      {U+02DD, U+030B}, // DOUBLE ACUTE ACCENT
      {U+00B4, U+0301}, // ACUTE ACCENT
      {U+007E, U+0303}, // TILDE
      {U+02DC, U+0303}, // SMALL TILDE
      {U+00A8, U+0308}, // DIAERESIS
      {U+02C7, U+030C}, // CARON
      {U+005E, U+0302}, // CIRCUMFLEX ACCENT
      {U+00AF, U+0305}, // MACRON
      {U+005F, ::::::}, // LOW LINE
      {U+2192, U+20D7}, // RIGHTWARDS ARROW
      {U+27F6, U+20D7}, // LONG RIGHTWARDS ARROW
      {U+2190, U+20D6}, // LEFT ARROW -->
  <xsl:function name="tr:ToUpperCombining" as="xs:string?">
    <xsl:param name="ch" as="xs:string?"/>
    <xsl:choose>
      <!-- BREVE -->
      <xsl:when test="$ch='&#x02D8;'">&#x0306;</xsl:when>
      <!-- CEDILLA -->
      <xsl:when test="$ch='&#x00B8;'">&#x0312;</xsl:when>
      <!-- GRAVE ACCENT -->
      <xsl:when test="$ch='&#x0060;'">&#x0300;</xsl:when>
      <!-- HYPHEN-MINUS/OVERLINE -->
      <xsl:when test="$ch='&#x002D;'">&#x0305;</xsl:when>
      <!-- MINUS SIGN/OVERLINE -->
      <xsl:when test="$ch='&#x2212;'">&#x0305;</xsl:when>
      <!-- FULL STOP/DOT ABOVE -->
      <xsl:when test="$ch='&#x002E;'">&#x0307;</xsl:when>
      <!-- DOT ABOVE -->
      <xsl:when test="$ch='&#x02D9;'">&#x0307;</xsl:when>
      <!-- DOUBLE ACUTE ACCENT -->
      <xsl:when test="$ch='&#x02DD;'">&#x030B;</xsl:when>
      <!-- ACUTE ACCENT -->
      <xsl:when test="$ch='&#x00B4;'">&#x0301;</xsl:when>
      <!-- TILDE -->
      <xsl:when test="$ch='&#x007E;'">&#x0303;</xsl:when>
      <!-- SMALL TILDE -->
      <xsl:when test="$ch='&#x02DC;'">&#x0303;</xsl:when>
      <!-- DIAERESIS -->
      <xsl:when test="$ch='&#x00A8;'">&#x0308;</xsl:when>
      <!-- CARON -->
      <xsl:when test="$ch='&#x02C7;'">&#x030C;</xsl:when>
      <!-- CIRCUMFLEX ACCENT -->
      <xsl:when test="$ch='&#x005E;'">&#x0302;</xsl:when>
      <!-- MACRON -->
      <xsl:when test="$ch='&#x00AF;'">&#x0305;</xsl:when>
      <!-- LOW LINE -->
      <!-- RIGHTWARDS ARROW -->
      <xsl:when test="$ch='&#x2192;'">&#x20D7;</xsl:when>
      <!-- LONG RIGHTWARDS ARROW -->
      <xsl:when test="$ch='&#x27F6;'">&#x20D7;</xsl:when>
      <!-- LEFT ARROW -->
      <xsl:when test="$ch='&#x2190;'">&#x20D6;</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$ch"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Template: match mover -->
  <xsl:template match="mml:mover" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'mover',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current" />
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <!-- Should this munder be interpreted as an OMML m:bar or m:acc? -->
        <!-- Check to see if this is an m:bar -->
        <xsl:choose>
          <xsl:when test="tr:FIsBar(.)">
            <m:bar>
              <m:barPr>
                <m:pos m:val="top" />
              </m:barPr>
              <m:e>
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current" />
              </m:e>
            </m:bar>
          </xsl:when>
          <xsl:otherwise>
            <!-- Not an m:bar, should it be an m:acc? -->
            <xsl:choose>
              <xsl:when test="tr:FIsAcc(.)">
                <m:acc>
                  <m:accPr>
                    <m:chr>
                      <xsl:attribute name="m:val" select="tr:ToUpperCombining(child::*[2])" />
                    </m:chr>
                  </m:accPr>
                  <m:e>
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[1]" mode="#current" />
                  </m:e>
                </m:acc>
              </xsl:when>
              <xsl:otherwise>
                <!-- This isn't an integral, overbar or accent, could it be a groupChr? -->
                <xsl:choose>
                  <xsl:when test="tr:FIsGroupChr(.)">
                    <xsl:element name="m:groupChr">
                      <xsl:sequence select="tr:CreateGroupChrPr('mml:mo',if (child::*[1][self::mml:mrow]) then 'top' else 'bot','bot')"/>
                      <xsl:element name="m:e">
                        <xsl:apply-templates select="mml:mrow" mode="#current" />
                      </xsl:element>
                    </xsl:element>
                  </xsl:when>
                  <xsl:otherwise>
                    <!-- Generic mover -->
                    <xsl:element name="m:limUpp">
                      <xsl:element name="m:e">
                        <xsl:sequence select="tr:CreateArgProp(.)" />
                        <xsl:apply-templates select="child::*[1]" mode="#current" />
                      </xsl:element>
                      <xsl:element name="m:lim">
                        <xsl:sequence select="tr:CreateArgProp(.)" />
                        <xsl:apply-templates select="child::*[2]" mode="#current" />
                      </xsl:element>
                    </xsl:element>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Template: match munderover -->
  <xsl:template match="mml:munderover" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'munderover',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current" />
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[3]" mode="#current" />
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="m:limUpp">
          <xsl:element name="m:e">
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:element name="m:limLow">
              <xsl:element name="m:e">
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current" />
              </xsl:element>
              <xsl:element name="m:lim">
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[2]" mode="#current" />
              </xsl:element>
            </xsl:element>
          </xsl:element>
          <xsl:element name="m:lim">
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[3]" mode="#current" />
          </xsl:element>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Template: match mfenced -->
  <xsl:template match="mml:mfenced" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:if test="not(tr:FIsNaryArgument(.) and not($display-in-nary))">
      <m:d>
        <xsl:sequence select="tr:CreateDelimProp((@open,@mml:open)[1],
                                                 (@separators,@mml:separators)[1],
                                                 (@close,@mml:close)[1])"/>
        <xsl:for-each select="*">
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="." mode="#current"/>
          </m:e>
        </xsl:for-each>
      </m:d>  
    </xsl:if>
  </xsl:template>

  <!-- %%Function: CreateDelimProp
		Given the characters to use as open, close and separators for the delim object, create the m:dPr (delim properties). 		
		MathML can have any number of separators in an mfenced object, but OMML can only represent one separator for each d (delim) object.
		So, we pick the first separator specified. -->
  <xsl:function name="tr:CreateDelimProp" as="element(m:dPr)?">
    <xsl:param name="chOpen" as="xs:string?"/>
    <xsl:param name="chSeparators" as="xs:string?" />
    <xsl:param name="chClose" as="xs:string?" />
    <xsl:variable name="chSep" select="substring($chSeparators, 1, 1)" />
    <!-- do we need a dPr at all? If everything's at its default value, then don't bother at all -->
    <xsl:if test="(not(empty($chOpen)) and not($chOpen = '(')) or
						      (not(empty($chClose)) and not($chClose = ')')) or 
						      not($chSep = '|')">
      <m:dPr>
        <!-- the default for MathML and OMML is '('. -->
        <xsl:if test="not(empty($chOpen)) and not($chOpen = '(')">
          <m:begChr>
            <xsl:attribute name="m:val" select="$chOpen" />
          </m:begChr>
        </xsl:if>
        <!-- the default for MathML is ',' and for OMML is '|' -->
        <xsl:choose>
          <!-- matches OMML's default, don't bother to write anything out -->
          <xsl:when test="$chSep = '|'" />
          <!-- Not specified, use MathML's default. We test against the existence of the actual attribute, not the substring -->
          <xsl:when test="empty($chSeparators)">
            <m:sepChr m:val=',' />
          </xsl:when>
          <xsl:otherwise>
            <m:sepChr>
              <xsl:attribute name="m:val" select="$chSep" />
            </m:sepChr>
          </xsl:otherwise>
        </xsl:choose>
        <!-- the default for MathML and OMML is ')'. -->
        <xsl:if test="not(empty($chClose)) and not($chClose = ')')">
          <m:endChr>
            <xsl:attribute name="m:val" select="$chClose" />
          </m:endChr>
        </xsl:if>
      </m:dPr>
    </xsl:if>
  </xsl:function>

  <xsl:function name="tr:LQuoteFromMs" as="xs:string?">
    <xsl:param name="msCur" />
    <xsl:choose>
      <xsl:when test="not(tr:check-existing-attributes($msCur,('lquote')))">
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="($msCur/@lquote,$msCur/@mml:lquote)[1]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:RQuoteFromMs" as="xs:string?">
    <xsl:param name="msCur"/>
    <xsl:choose>
      <xsl:when test="not(tr:check-existing-attributes($msCur,('rquote')))">
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="($msCur/@rquote,$msCur/@mml:rquote)[1]"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- %%Function: OutputMs -->
  <xsl:function name="tr:OutputMs" as="xs:string?">
    <xsl:param name="msCur" />
    <xsl:value-of select="concat(tr:LQuoteFromMs($msCur),normalize-space($msCur),tr:RQuoteFromMs($msCur))"/>
  </xsl:function>

  <!-- %%Template: match msub -->
  <xsl:template match="mml:msub" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'msub',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current" />
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <m:sSub>
          <m:sSubPr>
            <m:ctrlPr/>
          </m:sSubPr>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[1]" mode="#current"/>
          </m:e>
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current"/>
          </m:sub>
        </m:sSub>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Template: match msup -->
  <xsl:template match="mml:msup" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'msup',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current"/>
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <m:sSup>
          <m:sSupPr>
            <m:ctrlPr/>
          </m:sSupPr>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[1]" mode="#current"/>
          </m:e>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current"/>
          </m:sup>
        </m:sSup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Template: match msubsup -->
  <xsl:template match="mml:msubsup" mode="mml">
    <xsl:param name="display-in-nary" select="false()" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="tr:FIsNaryArgument(.) and not($display-in-nary)"/>
      <xsl:when test="tr:isNary(child::*[1])">
        <m:nary>
          <xsl:sequence select="tr:CreateNaryProp(.,normalize-space(child::*[1]),'msubsup',())" />
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current"/>
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[3]" mode="#current"/>
          </m:sup>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:sequence select="tr:NaryHandleMrowMstyle(.,following-sibling::*[1],())"/>
          </m:e>
        </m:nary>
      </xsl:when>
      <xsl:otherwise>
        <m:sSubSup>
          <m:sSubSupPr>
            <m:ctrlPr/>
          </m:sSubSupPr>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[1]" mode="#current"/>
          </m:e>
          <m:sub>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[2]" mode="#current"/>
          </m:sub>
          <m:sup>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[3]" mode="#current"/>
          </m:sup>
        </m:sSubSup>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- %%Function: SplitScripts 
		Takes an collection of nodes, and splits them odd and even into sup and sub scripts. Used for dealing with mmultiscript.
		This function assumes you want to output both a sub and sup element. -->
  <xsl:function name="tr:SplitScripts" as="element()+">
    <xsl:param name="context"/>
    <xsl:param name="ndScripts" />
    <m:sub>
      <xsl:sequence select="tr:CreateArgProp($context)" />
      <xsl:apply-templates select="$ndScripts[(position() mod 2) = 1]" mode="mml"/>
      <xsl:if test="$ndScripts[(position() mod 2) = 1]/local-name() = 'none'">
        <m:r>
          <m:t>
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:text xml:space="preserve"> </xsl:text>
          </m:t>
        </m:r>
      </xsl:if>
    </m:sub>
    <m:sup>
      <xsl:sequence select="tr:CreateArgProp($context)" />
      <xsl:apply-templates select="$ndScripts[(position() mod 2) = 0]" mode="mml"/>
      <xsl:if test="$ndScripts[(position() mod 2) = 0]/local-name() = 'none'">
        <m:r>
          <m:t>
            <xsl:attribute name="xml:space" select="'preserve'"/>
            <xsl:text xml:space="preserve"> </xsl:text>
          </m:t>
        </m:r>
      </xsl:if>
    </m:sup>
  </xsl:function>

  <!-- %%Template: match mmultiscripts
		There is some subtlety with the mml:mprescripts element. Everything that comes before that is considered a script (as opposed to a pre-script), but it need not be present. -->
  <xsl:template match="mml:mmultiscripts" mode="mml">
    <!-- count the nodes. Everything that comes after a mml:mprescripts is considered a pre-script;
			Everything that does not have an mml:mprescript as a preceding-sibling (and is not itself mml:mprescript) is a script, except for the first child which is always the base.
			The mml:none element is a place holder for a sub/sup element slot.
			mmultisript pattern:
			<mmultiscript>
				(base)
				(sub sup)* // Where <none/> can replace a sub/sup entry to preserve pattern.
				<mprescripts />
				(presub presup)*
			</mmultiscript> -->
    <!-- Count of presecript nodes that we'd print (this is essentially anything but the none placeholder. -->
    <xsl:variable name="cndPrescriptStrict" select="count(mml:mprescripts[1]/following-sibling::*[not(self::mml:none)])" />
    <!-- Count of all super script excluding mml:none -->
    <xsl:variable name="cndSuperScript" select="count(*[not(preceding-sibling::mml:mprescripts) and 
                                                        not(self::mml:mprescripts) and 
                                                        ((position() mod 2) = 1) and 
                                                        not(self::mml:none)]) - 1"/>
    <!-- Count of all sup script excluding mml:none -->
    <xsl:variable name="cndSubScript" select="count(*[not(preceding-sibling::mml:mprescripts) and 
                                                      not(self::mml:mprescripts) and 
                                                      ((position() mod 2) = 0) and 
                                                      not(self::mml:none)])"/>
    <!-- Count of all scripts excluding mml:none -->
    <xsl:variable name="cndScriptStrict" select="$cndSuperScript + $cndSubScript" />
    <!-- Count of all scripts including mml:none.  This is essentially all nodes before the first mml:mprescripts except the base. -->
    <xsl:variable name="cndScript" select="count(*[not(preceding-sibling::mml:mprescripts) and not(self::mml:mprescripts)]) - 1" />
    <xsl:choose>
      <!-- The easy case first. No prescripts, and no script ... just a base -->
      <xsl:when test="$cndPrescriptStrict &lt;= 0 and $cndScriptStrict &lt;= 0">
        <xsl:apply-templates select="*[1]" mode="#current"/>
      </xsl:when>
      <!-- Next, if there are no prescripts -->
      <xsl:when test="$cndPrescriptStrict &lt;= 0">
        <!-- we know we have some scripts or else we would have taken the earlier branch. -->
        <xsl:choose>
          <!-- We have both sub and super scripts-->
          <xsl:when test="$cndSuperScript &gt; 0 and $cndSubScript &gt; 0">
            <m:sSubSup>
              <m:sSubSupPr>
                <m:ctrlPr/>
              </m:sSubSupPr>
              <m:e>
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current"/>
              </m:e>
              <!-- Every child except the first is a script.  Do the split -->
              <xsl:sequence select="tr:SplitScripts(.,*[position() &gt; 1])" />
            </m:sSubSup>
          </xsl:when>
          <!-- Just a sub script -->
          <xsl:when test="$cndSubScript &gt; 0">
            <m:sSub>
              <m:sSubPr>
                <m:ctrlPr/>
              </m:sSubPr>
              <m:e>
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current"/>
              </m:e>
              <!-- No prescripts and no super scripts, therefore, it's a sub. -->
              <m:sub>
                <xsl:apply-templates select="*[position() &gt; 1]" mode="#current"/>
              </m:sub>
            </m:sSub>
          </xsl:when>
          <!-- Just super script -->
          <xsl:otherwise>
            <m:sSup>
              <m:sSupPr>
                <m:ctrlPr/>
              </m:sSupPr>
              <m:e>
                <xsl:sequence select="tr:CreateArgProp(.)" />
                <xsl:apply-templates select="child::*[1]" mode="#current"/>
              </m:e>
              <!-- No prescripts and no sub scripts, therefore, it's a sup. -->
              <m:sup>
                <xsl:apply-templates select="*[position() &gt; 1]" mode="#current"/>
              </m:sup>
            </m:sSup>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Next, if there are no scripts -->
      <xsl:when test="$cndScriptStrict &lt;= 0">
        <!-- we know we have some prescripts or else we would have taken the earlier branch. So, create an sPre and split the elements -->
        <m:sPre>
          <m:e>
            <xsl:sequence select="tr:CreateArgProp(.)" />
            <xsl:apply-templates select="child::*[1]" mode="#current"/>
          </m:e>
          <!-- The prescripts come after the mml:mprescript and if we get here we know there exists some elements after the mml:mprescript element. 
							The prescript element has no sub/subsup variation, therefore, even if we're only writing sub, we need to write out both the sub and sup element. -->
          <xsl:sequence select="tr:SplitScripts(.,mml:mprescripts[1]/following-sibling::*)" />
        </m:sPre>
      </xsl:when>
      <!-- Finally, the case with both prescripts and scripts. Create an sPre element to house the prescripts, with a sub/sup/subsup element at its base. -->
      <xsl:otherwise>
        <m:sPre>
          <m:e>
            <xsl:choose>
              <!-- We have both sub and super scripts-->
              <xsl:when test="$cndSuperScript &gt; 0 and $cndSubScript &gt; 0">
                <m:sSubSup>
                  <m:sSubSupPr>
                    <m:ctrlPr/>
                  </m:sSubSupPr>
                  <m:e>
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[1]" mode="#current"/>
                  </m:e>
                  <!-- scripts come before the mml:mprescript but after the first child, so their positions will be 2, 3, ... ($nndScript + 1) -->
                  <xsl:sequence select="tr:SplitScripts(.,*[(position() &gt; 1) and (position() &lt;= ($cndScript + 1))])" />
                </m:sSubSup>
              </xsl:when>
              <!-- Just a sub script -->
              <xsl:when test="$cndSubScript &gt; 0">
                <m:sSub>
                  <m:sSubPr>
                    <m:ctrlPr/>
                  </m:sSubPr>
                  <m:e>
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[1]" mode="#current"/>
                  </m:e>
                  <!-- We have prescripts but no super scripts, therefore, do a sub and apply templates to all tokens counted by cndScript. -->
                  <m:sub>
                    <xsl:apply-templates select="*[position() &gt; 1 and (position() &lt;= ($cndScript + 1))]" mode="#current"/>
                  </m:sub>
                </m:sSub>
              </xsl:when>
              <!-- Just super script -->
              <xsl:otherwise>
                <m:sSup>
                  <m:sSupPr>
                    <m:ctrlPr/>
                  </m:sSupPr>
                  <m:e>
                    <xsl:sequence select="tr:CreateArgProp(.)" />
                    <xsl:apply-templates select="child::*[1]" mode="#current"/>
                  </m:e>
                  <!-- We have prescripts but no sub scripts, therefore, do a sub and apply templates to all tokens counted by cndScript. -->
                  <m:sup>
                    <xsl:apply-templates select="*[position() &gt; 1 and (position() &lt;= ($cndScript + 1))]" mode="#current"/>
                  </m:sup>
                </m:sSup>
              </xsl:otherwise>
            </xsl:choose>
          </m:e>
          <!-- The prescripts come after the mml:mprescript and if we get here we know there exists one such element -->
          <xsl:sequence select="tr:SplitScripts(.,mml:mprescripts[1]/following-sibling::*)" />
        </m:sPre>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Function that determines if ndCur is an equation array.
			 ndCur is an equation array if:
			 1.  There are are no frame lines
			 2.  There are no column lines
			 3.  There are no row lines
			 4.  There is no row with more than 1 column  
			 5.  There is no row with fewer than 1 column
			 6.  There are no labeled rows. -->
  <xsl:function name="tr:FIsEqArray" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <!-- There should be no frame, columnlines, or rowlines -->
    <xsl:sequence select="not(tr:check-existing-attributes($ndCur,('frame','columnlines','rowlines'))) and
                          not($ndCur/mml:mtr[count(mml:mtd) &gt; 1]) and 
                          not($ndCur/mml:mtr[count(mml:mtd) &lt; 1]) and 
                          not($ndCur/mml:mlabeledtr)"/>
  </xsl:function>

  <!-- Function used to determine if we've already encountered an maligngroup or malignmark.
			 This is needed because omml has an implicit spacing alignment (omml spacing alignment = 
			 mathml's maligngroup element) at the beginning of each equation array row.  Therefore, 
			 the first maligngroup (implied or explicit) we encounter does not need to be output.  
			 This template recursively searches up the xml tree and looks at previous siblings to see 
			 if they have a descendant that is an maligngroup or malignmark.  We look for the malignmark 
			 to find the implicit maligngroup. -->
  <xsl:function name="tr:FFirstAlignAlreadyFound" as="xs:boolean">
    <xsl:param name="ndCur"/>
    <xsl:choose>
      <xsl:when test="count($ndCur/preceding-sibling::*[descendant-or-self::mml:maligngroup
								                                        or descendant-or-self::mml:malignmark]) &gt; 0">
        <xsl:sequence select="true()"/>
      </xsl:when>
      <xsl:when test="not($ndCur/parent::mml:mtd)">
        <xsl:sequence select="tr:FFirstAlignAlreadyFound($ndCur/parent::*)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="false()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- This template builds a string that is result of concatenating a given string several times. 
			 Given strToRepeat, create a string that has strToRepeat repeated iRepitions times. -->
  <xsl:function name="tr:ConcatStringRepeat">
    <xsl:param name="strToRepeat"/>
    <xsl:param name="iRepetitions"/>
    <xsl:param name="strBuilding"/>
    <xsl:choose>
      <xsl:when test="$iRepetitions &lt;= 0">
        <xsl:value-of select="$strBuilding" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="tr:ConcatStringRepeat($strToRepeat,$iRepetitions - 1,concat($strBuilding, $strToRepeat))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- This template determines if ndCur is a special collection.
			 By special collection, I mean is ndCur the outer element of some special grouping of mathml elements that actually represents some over all omml structure.
			 For instance, is ndCur a linear fraction, or an omml function. -->
  <xsl:function name="tr:FSpecialCollection" as="xs:boolean">
    <xsl:param name="ndCur" />
    <xsl:sequence select="if ($ndCur/self::mml:mrow) 
                          then (tr:FLinearFrac($ndCur) or tr:FIsFunc($ndCur) or tr:isNary($ndCur/*[1])) 
                          else false()"/>
  </xsl:function>

  <!-- This template iterates through the children of an equation array row (mtr) and outputs the equation.
			 This template does all the work to output ampersands and skip the right elements when needed. -->
  <xsl:function name="tr:ProcessEqArrayRow">
    <xsl:param name="ndCur" />
    <xsl:for-each select="$ndCur/*">
      <xsl:choose>
        <!-- If we have an alignment element output the ampersand. -->
        <xsl:when test="self::mml:maligngroup or self::mml:malignmark">
          <!-- Omml has an implied spacing alignment at the beginning of each equation.
					     Therefore, if this is the first ampersand to be output, don't actually output. -->
          <!-- Don't output unless it is an malignmark or we have already previously found an alignment point. -->
          <xsl:if test="self::mml:malignmark or tr:FFirstAlignAlreadyFound(.)">
            <m:r>
              <m:t>&amp;</m:t>
            </m:r>
          </xsl:if>
        </xsl:when>
        <!-- If this node is an non-special mrow or mstyle and we aren't supposed to ignore this collection, then go ahead an apply templates to this node. -->
        <xsl:when test="not(tr:FIsNaryArgument(.)) and ((self::mml:mrow and not(tr:FSpecialCollection(.))) or self::mml:mstyle)">
          <xsl:sequence select="tr:ProcessEqArrayRow(.)" />
        </xsl:when>
        <!-- At this point we have some mathml structure (fraction, nary, non-grouping element, etc.) -->
        <!-- If this mathml structure has alignment groups or marks as children, then extract those since omml can't handle that. -->
        <xsl:when test="descendant::mml:maligngroup[ancestor::mml:mtr[1]/generate-id()=
                                                    $ndCur/ancestor-or-self::mml:mtr[1]/generate-id()] or 
                        descendant::mml:malignmark[ancestor::mml:mtr[1]/generate-id()=
                                                   $ndCur/ancestor-or-self::mml:mtr[1]/generate-id()]">
          <xsl:variable name="cMalignGroups" 
                        select="count(descendant::mml:maligngroup[ancestor::mml:mtr[1]/generate-id() = 
                                                                  $ndCur/ancestor-or-self::mml:mtr[1]/generate-id()])" />
          <xsl:variable name="cMalignMarks"
                        select="count(descendant::mml:malignmark[ancestor::mml:mtr[1]/generate-id()=
                                                                 $ndCur/ancestor-or-self::mml:mtr[1]/generate-id()])" />
          <!-- Output all maligngroups and malignmarks as '&' -->
          <xsl:if test="$cMalignGroups + $cMalignMarks &gt; 0">
            <xsl:element name="m:r">
              <xsl:element name="m:t">
                <xsl:sequence select="tr:OutputText(tr:ConcatStringRepeat('&amp;',$cMalignGroups + $cMalignMarks,''))" />
              </xsl:element>
            </xsl:element>
          </xsl:if>
          <!-- Now that the '&' have been extracted, just apply-templates to this node.-->
          <xsl:apply-templates select="." mode="mml"/>
        </xsl:when>
        <!-- If there are no alignment points as descendants, then go ahead and output this node. -->
        <xsl:otherwise>
          <xsl:apply-templates select="." mode="mml"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <!-- This template transforms mtable into its appropriate omml type.
			 There are two possible omml constructs that an mtable can become:  a matrix or an equation array.
			 Because omml has no generic table construct, the omml matrix is the best approximate for a mathml table.
			 Our equation array transformation is very simple.  The main goal of this transform is to
			 allow roundtripping omml eq arrays through mathml.  The template ProcessEqArrayRow was never
			 intended to account for many of the alignment flexibilities that are present in mathml like 
			 using the alig attribute, using alignmark attribute in token elements, etc.
			 The restrictions on this transform require <malignmark> and <maligngroup> elements to be outside of
			 any non-grouping mathml elements (that is, mrow and mstyle).  Moreover, these elements cannot be the children of
			 mrows that represent linear fractions or functions.  Also, <malignmark> cannot be a child
			 of token attributes.
			 In the case that the above -->
  <xsl:template match="mml:mtable" mode="mml">
    <xsl:choose>
      <xsl:when test="tr:FIsEqArray(.)">
        <xsl:element name="m:eqArr">
          <xsl:for-each select="mml:mtr">
            <xsl:element name="m:e">
              <xsl:sequence select="tr:ProcessEqArrayRow(mml:mtd)" />
            </xsl:element>
          </xsl:for-each>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="cMaxElmtsInRow" select="tr:CountMaxElmtsInRow(*[1],0)"/>
        <m:m>
          <m:mPr>
            <m:baseJc m:val="center" />
            <m:plcHide m:val="on" />
            <m:mcs>
              <m:mc>
                <m:mcPr>
                  <m:count>
                    <xsl:attribute name="m:val" select="$cMaxElmtsInRow" />
                  </m:count>
                  <m:mcJc m:val="left" />
                </m:mcPr>
              </m:mc>
            </m:mcs>
          </m:mPr>
          <xsl:for-each select="*">
            <xsl:choose>
              <xsl:when test="self::mml:mtr or self::mml:mlabeledtr">
                <m:mr>
                  <xsl:choose>
                    <xsl:when test="self::mml:mtr">
                      <xsl:for-each select="*">
                        <m:e>
                          <xsl:apply-templates select="." mode="#current"/>
                        </m:e>
                      </xsl:for-each>
                      <xsl:sequence select="tr:CreateEmptyElmt($cMaxElmtsInRow - count(*))" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:for-each select="*[position() &gt; 1]">
                        <m:e>
                          <xsl:apply-templates select="." mode="#current"/>
                        </m:e>
                      </xsl:for-each>
                      <xsl:sequence select="tr:CreateEmptyElmt($cMaxElmtsInRow - (count(*) - 1))" />
                    </xsl:otherwise>
                  </xsl:choose>
                </m:mr>
              </xsl:when>
              <xsl:otherwise>
                <m:mr>
                  <m:e>
                    <xsl:apply-templates select="." mode="#current"/>
                  </m:e>
                  <xsl:sequence select="tr:CreateEmptyElmt($cMaxElmtsInRow - 1)" />
                </m:mr>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </m:m>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <xsl:template match="m:mtd" mode="mml">
    <xsl:apply-templates select="*" mode="#current"/>
  </xsl:template>
  
  <xsl:function name="tr:CreateEmptyElmt">
    <xsl:param name="cEmptyMtd" />
    <xsl:if test="$cEmptyMtd &gt; 0">
      <m:e></m:e>
      <xsl:sequence select="tr:CreateEmptyElmt($cEmptyMtd - 1)" />
    </xsl:if>
  </xsl:function>
  
  <xsl:function name="tr:CountMaxElmtsInRow">
    <xsl:param name="ndCur" />
    <xsl:param name="cMaxElmtsInRow" />
    <xsl:choose>
      <xsl:when test="not($ndCur)">
        <xsl:value-of select="$cMaxElmtsInRow" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="cMaxElmtsInRow-param">
          <xsl:choose>
            <xsl:when test="local-name($ndCur) = 'mlabeledtr' and namespace-uri($ndCur) = 'http://www.w3.org/1998/Math/MathML'">
              <xsl:choose>
                <xsl:when test="(count($ndCur/*) - 1) &gt; $cMaxElmtsInRow">
                  <xsl:value-of select="count($ndCur/*) - 1" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$cMaxElmtsInRow" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="local-name($ndCur) = 'mtr' and namespace-uri($ndCur) = 'http://www.w3.org/1998/Math/MathML'">
              <xsl:choose>
                <xsl:when test="count($ndCur/*) &gt; $cMaxElmtsInRow">
                  <xsl:value-of select="count($ndCur/*)" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$cMaxElmtsInRow" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="1 &gt; $cMaxElmtsInRow">
                  <xsl:value-of select="1" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$cMaxElmtsInRow" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:sequence select="tr:CountMaxElmtsInRow($ndCur/following-sibling::*[1],$cMaxElmtsInRow-param)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:function name="tr:GetMglyphAltText" as="xs:string?">
    <xsl:param name="ndCur" />
    <xsl:sequence select="normalize-space(($ndCur/@alt,$ndCur/@mml:alt)[1])"/>
  </xsl:function>

  <xsl:template match="mml:mglyph" mode="mml">
    <xsl:element name="m:r">
      <xsl:element name="m:rPr">
        <xsl:element name="m:nor" />
      </xsl:element>
      <xsl:element name="m:t">
        <xsl:sequence select="tr:OutputText(tr:GetMglyphAltText(.))" />
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="mml:mspace[matches(@width, '^[1-9]\d*(.\d+)?em$')]" mode="mml">
    <xsl:element name="m:r">
      <xsl:element name="m:t">
        <xsl:attribute name="xml:space" select="'preserve'"/>
        <xsl:for-each select="1 to xs:integer(replace(@width, '^([1-9]\d*)(\.\d+)?em$', '$1')) * 4">
          <xsl:text xml:space="preserve"> </xsl:text>
        </xsl:for-each>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <xsl:template match="mml:mspace[not(matches(@width, '^[1-9]\d*(.\d+)?em$'))]" mode="mml">
    <xsl:element name="m:r">
      <xsl:element name="m:t">
        <xsl:attribute name="xml:space" select="'preserve'"/>
        <xsl:text xml:space="preserve"> </xsl:text>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- Omml doesn't really support mglyph, so just output the alt text -->
  <xsl:template match="mml:mi[child::mml:mglyph] | 
	                     mml:mn[child::mml:mglyph] | 
	                     mml:mo[child::mml:mglyph] | 
	                     mml:ms[child::mml:mglyph] | 
	                     mml:mtext[child::mml:mglyph]" mode="mml">
    <xsl:param name="maligngroup" as="xs:boolean"/>
    <xsl:variable name="mathvariant" select="(@mathvariant,@mml:mathvariant)[1]"/>
    <xsl:variable name="fontstyle" select="(@fontstyle,@mml:fontstyle)[1]"/>
    <xsl:variable name="fontweight" select="(@fontweight,@mml:fontweight)[1]"/>
    <xsl:variable name="mathcolor" select="(@mathcolor,@mml:mathcolor)[1]"/>
    <xsl:variable name="mathbackground" select="(@mathbackground,@mml:mathbackground)[1]"/>
    <xsl:variable name="mathsize" select="(@mathsize,@mml:mathsize)[1]"/>
    <xsl:variable name="color" select="(@color,@mml:color)[1]"/>
    <xsl:variable name="fontsize" select="(@fontsize,@mml:fontsize)[1]"/>
    <!-- Output MS Left Quote (if need be) -->
    <xsl:if test="self::mml:ms">
      <xsl:element name="m:r">
        <xsl:sequence select="tr:CreateRunProp($mathbackground,$mathcolor,$mathvariant,$color,$fontsize,$fontstyle,
                                               $fontweight,$mathsize,.,tr:FNor(.),$maligngroup)" />
        <xsl:element name="m:t">
          <xsl:sequence select="tr:OutputText(tr:LQuoteFromMs(.))"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
    <xsl:for-each select="mml:mglyph | text()">
      <xsl:variable name="str">
        <xsl:choose>
          <xsl:when test="self::mml:mglyph">
            <xsl:sequence select="tr:GetMglyphAltText(.)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="string-length($str) &gt; 0">
        <xsl:element name="m:r">
          <xsl:variable name="fNor-param" as="xs:boolean">
            <xsl:choose>
              <xsl:when test="self::mml:mglyph">
                <xsl:sequence select="true()"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="tr:FNor(.)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:sequence select="tr:CreateRunProp($mathbackground,$mathcolor,$mathvariant,$color,$fontsize,$fontstyle,
                                                 $fontweight,$mathsize,.,$fNor-param,$maligngroup)" />
          <xsl:element name="m:t">
            <xsl:sequence select="tr:OutputText($str)"/>
          </xsl:element>
        </xsl:element>
      </xsl:if>
    </xsl:for-each>

    <!-- Output MS Right Quote (if need be) -->
    <xsl:if test="self::mml:ms">
      <xsl:element name="m:r">
        <xsl:sequence select="tr:CreateRunProp($mathbackground,$mathcolor,$mathvariant,$color,$fontsize,$fontstyle,
                                               $fontweight,$mathsize,.,tr:FNor(.),$maligngroup)" />
        <xsl:element name="m:t">
          <xsl:sequence select="tr:OutputText(tr:RQuoteFromMs(.))"/>
        </xsl:element>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:function name="tr:FStrContainsDigits" as="xs:boolean">
    <xsl:param name="s" />
    <!-- Translate any digit into a 0 -->
      <!-- Search for 0s -->
      <xsl:sequence select="matches($s, '[0-9]')"/>
  </xsl:function>

  <!-- Used to determine if mpadded attribute {width, height, depth }  indicates to show everything. 
       Unlike mathml, whose mpadded structure has great flexibility in modifying the 
       bounding box's width, height, and depth, Word can only have zero or full width, height, and depth.
       Thus, if the width, height, or depth attributes indicate any kind of nonzero width, height, 
       or depth, we'll translate that into a show full width, height, or depth for OMML.  Only if the attribute
       indicates a zero width, height, or depth, will we report back FFull as false.
       Example:  s=0%    ->  FFull returns 0.
                 s=2%    ->  FFull returns 1.
                 s=0.1em ->  FFull returns 1. -->
  <xsl:function name="tr:FFull" as="xs:boolean">
    <xsl:param name="s" />
    <xsl:sequence select="not(matches($s, '^0+(\.0+)?(%|em|px)?$'))"/>
  </xsl:function>

  <!-- Just outputs phant properties, doesn't do any fancy thinking of its own, just obeys the defaults of phants. -->
  <xsl:function name="tr:CreatePhantPropertiesCore" as="element(m:phantPr)?">
    <xsl:param name="fShow" as="xs:boolean"/>
    <xsl:param name="fFullWidth" as="xs:boolean"/>
    <xsl:param name="fFullHeight" as="xs:boolean"/>
    <xsl:param name="fFullDepth" as="xs:boolean"/>
    <xsl:if test="not($fShow) or not($fFullWidth) or not($fFullHeight) or not($fFullDepth)">
      <xsl:element name="m:phantPr">
        <xsl:if test="not($fShow)">
          <xsl:element name="m:show">
            <xsl:attribute name="m:val">off</xsl:attribute>
          </xsl:element>
        </xsl:if>
        <xsl:if test="not($fFullWidth)">
          <xsl:element name="m:zeroWid">
            <xsl:attribute name="m:val">on</xsl:attribute>
          </xsl:element>
        </xsl:if>
        <xsl:if test="not($fFullHeight)">
          <xsl:element name="m:zeroAsc">
            <xsl:attribute name="m:val">on</xsl:attribute>
          </xsl:element>
        </xsl:if>
        <xsl:if test="not($fFullDepth)">
          <xsl:element name="m:zeroDesc">
            <xsl:attribute name="m:val">on</xsl:attribute>
          </xsl:element>
        </xsl:if>
      </xsl:element>
    </xsl:if>
  </xsl:function>

  <!-- Figures out if we should factor in width, height, and depth attributes.  
       If so, then it gets these attributes, does some processing to figure out what the attributes indicate, 
       then passes these indications to CreatePhantPropertiesCore.  
       If we aren't supposed to factor in width, height, or depth, then we'll just output the show attribute. -->
  <xsl:function name="tr:CreatePhantProperties" as="element(m:phantPr)?">
    <xsl:param name="ndCur"/>
    <xsl:param name="fShow" as="xs:boolean"/>
    <xsl:choose>
      <!-- In the special case that we have an mphantom with one child which is an mpadded, then we should 
           subsume the mpadded attributes into the mphantom attributes.  The test statement below imples the 
           'one child which is an mpadded'.  The first part, that the parent of mpadded is an mphantom, is implied
           by being in this template, which is only called when we've encountered an mphantom.
           Word outputs its invisible phantoms with smashing as 
              <mml:mphantom>
                <mml:mpadded . . . >
                </mml:mpadded>
              </mml:mphantom>
            This test is used to allow roundtripping smashed invisible phantoms. -->
      <xsl:when test="count($ndCur/child::*)=1 and count($ndCur/mml:mpadded)=1">
        <xsl:variable name="sLowerCaseWidth" select="lower-case(($ndCur/mml:mpadded/@width,$ndCur/mml:mpadded/@mml:width)[1])"/>
        <xsl:variable name="sLowerCaseHeight" select="lower-case(($ndCur/mml:mpadded/@height,$ndCur/mml:mpadded/@mml:height)[1])"/>
        <xsl:variable name="sLowerCaseDepth" select="lower-case(($ndCur/mml:mpadded/@depth,$ndCur/mml:mpadded/@mml:depth)[1])"/>
        <xsl:sequence select="tr:CreatePhantPropertiesCore($fShow,tr:FFull($sLowerCaseWidth),
                                                           tr:FFull($sLowerCaseHeight),tr:FFull($sLowerCaseDepth))" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="tr:CreatePhantPropertiesCore($fShow,true(),true(),true())"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <xsl:template match="mml:mpadded" mode="mml">
    <xsl:choose>
      <xsl:when test="count(parent::mml:mphantom)=1 and count(preceding-sibling::*)=0 and count(following-sibling::*)=0">
        <!-- This mpadded is inside an mphantom that has already setup phantom attributes, therefore, just apply templates -->
        <xsl:apply-templates select="*" mode="#current"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="m:phant">
          <xsl:sequence select="tr:CreatePhantPropertiesCore(true(),tr:FFull((@width,@mml:width)[1]),
                                                             tr:FFull((@height,@mml:height)[1]),tr:FFull((@depth,@mml:depth)[1]))" />
          <m:e>
            <xsl:apply-templates select="*" mode="#current"/>
          </m:e>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="mml:mphantom" mode="mml">
    <xsl:element name="m:phant">
      <xsl:sequence select="tr:CreatePhantProperties(.,false())" />
      <m:e>
        <xsl:apply-templates select="*" mode="#current"/>
      </m:e>
    </xsl:element>
  </xsl:template>

  <xsl:function name="tr:isNaryOper" as="xs:boolean">
    <xsl:param name="sNdCur" />
    <xsl:sequence select="($sNdCur = 
                           ('&#x222B;','&#x222C;','&#x222D;','&#x222E;','&#x222F;','&#x2230;','&#x2232;','&#x2233;','&#x2231;',
                            '&#x2229;','&#x222A;','&#x220F;','&#x2210;','&#x2211;','&#x22C0;','&#x22C1;','&#x22C2;','&#x22C3;'))" />
  </xsl:function>


  <xsl:function name="tr:isNary" as="xs:boolean">
    <!-- ndCur is the element around the nAry operator -->
    <xsl:param name="ndCur" />
    <!-- Narys shouldn't be MathML accents.  -->
    <xsl:variable name="sLowerCaseAccent">
      <xsl:choose>
        <xsl:when test="$ndCur/parent::*[self::mml:munder]">
          <xsl:value-of select="lower-case(($ndCur/parent::*[self::mml:munder]/@accentunder,
                                            $ndCur/parent::*[self::mml:munder]/@mml:accentunder)[1])"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(($ndCur/parent::*/@accent,$ndCur/parent::*/@mml:accent)[1])"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
      <!-- This ndCur is in fact part of an nAry if
           1)  The last descendant of ndCur (which could be ndCur itself) is an operator.
           2)  Along that chain of descendants we only encounter mml:mo, mml:mstyle, and mml:mrow elements.
           3)  the operator in mml:mo is a valid nAry operator
           4)  The nAry is not accented. -->
      <xsl:sequence select="tr:isNaryOper(normalize-space($ndCur)) and 
                            not(xs:boolean($sLowerCaseAccent='true')) and 
                            $ndCur/descendant-or-self::*[last()]/self::mml:mo and 
                            not($ndCur/descendant-or-self::*[not(self::mml:mo or self::mml:mstyle or self::mml:mrow)])"/>
  </xsl:function>

  <xsl:function name="tr:CreateNaryProp" as="element(m:naryPr)">
    <xsl:param name="context"/>
    <xsl:param name="chr" as="xs:string?"/>
    <xsl:param name="sMathmlType" as="xs:string"/>
    <xsl:param name="sGrow-param" as="xs:string?"/>
    <xsl:variable name="sGrow" as="xs:string?">
      <xsl:choose>
        <xsl:when test="not(empty($sGrow-param))">
          <xsl:sequence select="$sGrow-param"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="lower-case(($context/child::*[1]/@stretchy,$context/child::*[1]/@mml:stretchy)[1])"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <m:naryPr>
      <m:chr>
        <xsl:attribute name="m:val" select="$chr" />
      </m:chr>
      <m:limLoc>
        <xsl:attribute name="m:val">
          <xsl:choose>
            <xsl:when test="$sMathmlType=('munder','mover','munderover','mrow')">
              <xsl:text>undOvr</xsl:text>
            </xsl:when>
            <xsl:when test="$sMathmlType=('msub','msup','msubsup')">
              <xsl:text>subSup</xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:attribute>
      </m:limLoc>
      <m:grow>
        <xsl:attribute name="m:val">
          <xsl:choose>
            <xsl:when test="$sGrow='true'">1</xsl:when>
            <xsl:when test="$sGrow='false'">0</xsl:when>
            <xsl:when test="$chr=('&#x222B;','&#x222E;','&#x222F;','&#x2232;','&#x2233;','&#x2229;','&#x222A;','&#x220F;','&#x2211;',
                                  '&#x22C0;','&#x22C1;','&#x22C2;','&#x22C3;')">1</xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </m:grow>
      <m:subHide>
        <xsl:attribute name="m:val">
          <xsl:choose>
            <xsl:when test="$sMathmlType=('mover','msup','mrow')">
              <xsl:text>on</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>off</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </m:subHide>
      <m:supHide>
        <xsl:attribute name="m:val">
          <xsl:choose>
            <xsl:when test="$sMathmlType=('munder','msub','mrow')">
              <xsl:text>on</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text>off</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>
      </m:supHide>
    </m:naryPr>
  </xsl:function>
  
</xsl:stylesheet>
<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:docx2hub = "http://transpect.io/docx2hub"
  xmlns:hub2docx = "http://transpect.io/hub2docx"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:tr="http://transpect.io" 
  version="1.0"
  name="mml-dir2docx"
  type="hub2docx:mml-dir2docx">
  
  <p:documentation>Convert all MathML files in a folder to OMML and embed them in a docx file</p:documentation>
  
  <p:output port="result" primary="true">
    <p:pipe port="result" step="create-hub"/>
  </p:output>
  <p:serialization port="result" omit-xml-declaration="false" indent="true"/>
  
  <p:option name="dir" required="true"/>
  <p:option name="filter" select="'.+\.mml$'"></p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="'file:/tmp/debug'"/>

  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/xproc-util/file-uri/xpl/file-uri.xpl"/>
  <p:import href="http://transpect.io/docx_modify/xpl/docx_modify.xpl"/>

  <tr:file-uri fetch-http="false" filename="http://transpect.io/hub2docx/templates/normal.docx" name="template">
    <p:input port="resolver">
      <p:document href="http://transpect.io/xslt-util/xslt-based-catalog-resolver/xsl/resolve-uri-by-catalog.xsl"/>
    </p:input>
    <p:input port="catalog">
      <p:document href="http://this.transpect.io/xmlcatalog/catalog.xml"/>
    </p:input>
  </tr:file-uri>
  
  <p:sink name="sink1"/>
  
  <tr:file-uri fetch-http="false" name="dir">
    <p:with-option name="filename" select="$dir"/>
  </tr:file-uri>

  <p:directory-list name="dirlist">
    <p:with-option name="include-filter" select="$filter"/>
    <p:with-option name="path" select="/*/@local-href"/>
  </p:directory-list>
  
  <p:viewport match="c:file" name="file-viewport">
    <p:load name="load">
      <p:with-option name="href" select="resolve-uri(/*/@name, base-uri(/*))"/>
    </p:load>
    <p:sink name="sink2"/>
    <p:insert name="insert" position="last-child">
      <p:input port="source">
        <p:pipe port="current" step="file-viewport"/>
      </p:input>
      <p:input port="insertion">
        <p:pipe port="result" step="load"/>
      </p:input>
    </p:insert>
  </p:viewport>

  <p:xslt name="create-hub">
    <p:input port="parameters">
      <p:empty/>
    </p:input>
    <p:input port="stylesheet">
      <p:inline>
        <xsl:stylesheet version="2.0" xmlns="http://docbook.org/ns/docbook">
          <xsl:template match="/">
            <hub>
              <xsl:apply-templates select="//mml:math"/>
            </hub>
          </xsl:template>
          <xsl:template match="mml:math[@display = 'block']" priority="2">
            <informaltable>
              <tgroup>
                <tbody>
                  <row>
                    <entry>
                      <para>
                        <xsl:value-of select="../@name"/>
                      </para>
                    </entry>
                    <entry>
                      <informalequation>
                        <xsl:apply-templates select="." mode="mml"/>
                      </informalequation>
                    </entry>
                  </row>
                </tbody>
              </tgroup>
            </informaltable>
          </xsl:template>
          <xsl:template match="mml:math" priority="1">
            <para>
              <xsl:value-of select="../@name"/>
              <tab/>
              <inlineequation>
                <xsl:apply-templates select="." mode="mml"/>
              </inlineequation>
            </para>
          </xsl:template>
          <xsl:template match="node() | @*" mode="mml">
            <xsl:copy>
              <xsl:apply-templates select="@*, node()" mode="#current"/>
            </xsl:copy>
          </xsl:template>
          <!--<xsl:template match="*[mml:mo[@largeop = 'true'][following-sibling::*[1][not(local-name()=('mrow','mstyle'))]]]" mode="mml">
            <xsl:copy>
              <xsl:for-each-group select="*" 
                group-starting-with="mml:mo[@largeop = 'true'][following-sibling::*[1][not(local-name()=('mrow','mstyle'))]]">
                <xsl:choose>
                  <xsl:when test="self::mml:mo[@largeop = 'true'][following-sibling::*[1][not(local-name()=('mrow','mstyle'))]]">
                    <xsl:copy-of select="."/>
                    <mml:mrow>
                      <xsl:apply-templates select="current-group()[position() gt 1]" mode="#current"/>
                    </mml:mrow>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="current-group()" mode="#current"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each-group>
            </xsl:copy>
          </xsl:template>-->
        </xsl:stylesheet>
      </p:inline>
    </p:input>
  </p:xslt>
  <!--
  <p:xslt  initial-mode="mml2tex-grouping">
    <p:input port="stylesheet">
      <p:document href="http://transpect.io/mml-normalize/xsl/mml-normalize.xsl"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  
  <p:xslt name="mml-normalize" initial-mode="mml2tex-preprocess">
    <p:input port="stylesheet">
      <p:document href="http://transpect.io/mml-normalize/xsl/mml-normalize.xsl"/>
    </p:input>
    <p:input port="parameters"><p:empty/></p:input>
  </p:xslt>
  -->
  <p:sink name="sink4"/>
  
  <docx2hub:modify>
    <p:input port="xslt">
      <p:document href="http://transpect.io/hub2docx/xsl/hub2docx.xsl"/>
    </p:input>
    <p:input port="xpl">
      <p:document href="http://transpect.io/hub2docx/xpl/hub2docx.xpl"/>
    </p:input>
    <p:with-option name="file" select="/*/@local-href">
      <p:pipe port="result" step="template"/>
    </p:with-option>
    <p:with-option name="extract-dir" select="concat(/*/@local-href, 'template.docx.tmp')">
      <p:pipe port="result" step="dir"/>
    </p:with-option>
    <p:input port="external-sources">
      <p:pipe port="result" step="create-hub"/>
<!--      <p:pipe port="result" step="mml-normalize"/>-->
    </p:input>
    <p:input port="params"><p:empty/></p:input>
    <p:input port="options"><p:empty/></p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </docx2hub:modify>
  
  <p:sink name="sink3"/>
  
</p:declare-step>

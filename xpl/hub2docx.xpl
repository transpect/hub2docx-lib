<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:hub2htm="http://transpect.io/hub2htm" 
  xmlns:hub2docx = "http://transpect.io/hub2docx"
  xmlns:tr="http://transpect.io" 
  version="1.0"
  name="hub2docx"
  type="hub2docx:modify">
  
  <p:documentation>This is meant to be fed into the xpl port of http://transpect.io/docx_modify/xpl/docx_modify.xpl</p:documentation>
  
  <p:option name="file" required="true">
    <p:documentation>A docx template file. Parts of it will be replaced with the transformed
    source document.
    The file option will probably not be used here, so declare it obsolete?</p:documentation>
  </p:option>
  <p:option name="copy-media" required="false" select="'false'">
    <p:documentation>Whether to copy resources with absolute file: URIs to word/media in the target docx directory</p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  <p:option name="status-dir-uri" required="false" select="'debug/status?enabled=false'"/>
  
  <p:input port="source" primary="true" sequence="true">
    <p:documentation>Document 1: Single tree of the template docx file. (?)
      Document 2: A Hub XML document (version 1.2 or newer).
    Please note that the following mapping will occur:
    - keywordset[@role='custom-meta'] will map to {http://schemas.openxmlformats.org/officeDocument/2006/custom-properties}Properties in docProps/custom.xml (editable in the Word UI)
    - keywordset[@role='docVars'] will map to w:docVars in word/settings.xml</p:documentation>
  </p:input>
  <p:input port="stylesheet">
    <p:document href="../xsl/hub2docx.xsl"/>
  </p:input>
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" />
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.io/xproc-util/xslt-mode/xpl/xslt-mode.xpl"/>
  <p:import href="http://transpect.io/xproc-util/store-debug/xpl/store-debug.xpl"/>
  <p:import href="http://transpect.io/xproc-util/copy-files/xpl/copy-files.xpl"/>

  <p:split-sequence name="split" test="position() = 1" initial-only="true">
    <p:documentation>The first one (matched port) is the single tree</p:documentation>
  </p:split-sequence>

  <p:sink/>
  
  <p:identity name="matched-and-not-matched">
    <p:input port="source">
      <p:pipe step="split" port="not-matched"/>
      <p:pipe step="split" port="matched"/>
    </p:input>
  </p:identity>

  <p:wrap-sequence wrapper="tmp"/>

  <tr:store-debug pipeline-step="hub2docx/5.split-sequence">
    <p:with-option name="active" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="base-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </tr:store-debug>

  <p:sink/>

  <p:choose name="conditionally-copy-media">
    <p:when test="$copy-media = 'true'">
      <p:output port="result" primary="true"/>
      <tr:copy-files>
        <p:input port="source">
          <p:pipe port="not-matched" step="split"/>
        </p:input>
        <p:with-option name="fileref-attribute-value-regex" select="'^file:/'"/>
        <p:with-option name="target-dir-uri" select="concat(/*/@extract-dir-uri, 'word/media')">
          <p:pipe port="matched" step="split"/>
        </p:with-option>
        <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
        <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
        <p:with-option name="status-dir-uri" select="$status-dir-uri"><p:empty/></p:with-option>
      </tr:copy-files>
      <tr:store-debug pipeline-step="hub2docx/7.copy-files">
        <p:with-option name="active" select="$debug"><p:empty/></p:with-option>
        <p:with-option name="base-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
      </tr:store-debug>
    </p:when>
    <p:otherwise>
      <p:output port="result" primary="true"/>
      <p:identity>
        <p:input port="source">
          <p:pipe port="not-matched" step="split"/>
        </p:input>
      </p:identity>
    </p:otherwise>
  </p:choose>

  <p:sink/>

  <tr:xslt-mode name="transformed-hub" msg="yes" mode="hub:default" prefix="hub2docx/10">
    <p:input port="source">
      <p:pipe port="result" step="conditionally-copy-media"/>
      <p:pipe step="split" port="matched"/>
    </p:input>
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:with-option name="debug" select="$debug"><p:empty/></p:with-option>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"><p:empty/></p:with-option>
  </tr:xslt-mode>
  
  <p:sink/>
  
  <tr:xslt-mode name="clean-hub" msg="yes" mode="hub:clean" prefix="hub2docx/15">
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:input port="source">
      <p:pipe step="transformed-hub" port="result"/>
      <p:pipe step="split" port="matched"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
  <p:sink/>
  
  <tr:xslt-mode name="merge" msg="yes" mode="hub:merge" prefix="hub2docx/50">
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:input port="source">
      <p:pipe step="split" port="matched"/>
      <p:pipe step="clean-hub" port="result"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </tr:xslt-mode>
  
</p:declare-step>

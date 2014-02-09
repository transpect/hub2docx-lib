<?xml version="1.0" encoding="utf-8"?>
<p:declare-step xmlns:p="http://www.w3.org/ns/xproc" 
  xmlns:c="http://www.w3.org/ns/xproc-step"  
  xmlns:cx="http://xmlcalabash.com/ns/extensions" 
  xmlns:cxf="http://xmlcalabash.com/ns/extensions/fileutils"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:s="http://purl.oclc.org/dsdl/schematron"
  xmlns:bc="http://transpect.le-tex.de/book-conversion"
  xmlns:transpect="http://www.le-tex.de/namespace/transpect"
  xmlns:hub2htm="http://www.le-tex.de/namespace/hub2htm" 
  xmlns:hub2docx = "http://www.le-tex.de/namespace/hub2docx"
  xmlns:din="http://din.de/namespace"
  xmlns:letex="http://www.le-tex.de/namespace" 
  version="1.0"
  name="hub2docx"
  type="hub2docx:modify"
  >
  
  <p:documentation>This is meant to be fed into the xpl port of http://transpect.le-tex.de/docx_modify/xpl/docx_modify.xpl</p:documentation>
  
  <p:option name="file" required="true">
    <p:documentation>A docx template file. Parts of it will be replaced with the transformed
    source document.
    The file option will probably not be used here, so declare it obsolete?</p:documentation>
  </p:option>
  <p:option name="debug" required="false" select="'no'"/>
  <p:option name="debug-dir-uri" required="false" select="resolve-uri('debug')"/>
  
  <p:input port="source" primary="true" sequence="true">
    <p:documentation>A Hub XML document (version 1.1 or newer).
    Please note that the following mapping will occur:
    - keyowrdset[@role='custom-meta'] will map to {http://schemas.openxmlformats.org/officeDocument/2006/custom-properties}Properties in docProps/custom.xml (editable in the Word UI)
    - keywordset[@role='docVars'] will map to w:docVars in word/settings.xml</p:documentation>
  </p:input>
  <p:input port="stylesheet" />
  <p:input port="parameters" kind="parameter" primary="true"/>
  <p:output port="result" primary="true" />
  
  <p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl" />
  <p:import href="http://transpect.le-tex.de/xproc-util/xslt-mode/xslt-mode.xpl"/>

  <p:split-sequence name="split" test="position() = 1" initial-only="true"/>

  <p:sink/>

  <letex:xslt-mode name="transformed-hub" msg="yes" mode="hub:default" prefix="hub2docx/10">
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:input port="source">
      <p:pipe step="split" port="not-matched"/>
      <p:pipe step="split" port="matched"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>

  <letex:xslt-mode name="clean-hub" msg="yes" mode="hub:clean" prefix="hub2docx/15">
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:input port="source">
      <p:pipe step="transformed-hub" port="result"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>

  <letex:xslt-mode name="merge" msg="yes" mode="hub:merge" prefix="hub2docx/50">
    <p:input port="models"><p:empty/></p:input>
    <p:input port="stylesheet"><p:pipe port="stylesheet" step="hub2docx"/></p:input>
    <p:input port="source">
      <p:pipe step="split" port="matched"/>
      <p:pipe step="clean-hub" port="result"/>
    </p:input>
    <p:with-option name="debug" select="$debug"/>
    <p:with-option name="debug-dir-uri" select="$debug-dir-uri"/>
  </letex:xslt-mode>
  
</p:declare-step>

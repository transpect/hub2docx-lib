#!/usr/bin/env bash
export SAXON_CP=saxon/saxon9he.jar
xspec-master/bin/xspec.sh xspec/mml2omml.xspec
grep 'class="failed"' xspec/mml2omml-result.html >/dev/null 2>&1
test ! $? -eq 0

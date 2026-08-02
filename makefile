
define package
{
  login: vthierry
  logo: "docs/idnai-logo-ocre.png"
  keywords: [ raspberry esp32 web-service weak-json ]
  dependencies: [ jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor idnai-json ]
  os: [ Linux armv7l esp32 mingw64 ]
}
endef

include src/makefile-rules.mk


define package
{
  login: vthierry
  logo: "docs/idnai-logo-ocre.png"
  keywords: [ raspberry esp32 web-service weak-json ]
  dependencies: [ jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor idnai-json ]
  os: [ Linux armv7l esp32 mingw64 ]
}
endef

INSTALL = setup-install
TEST = setup-test

include src/makefile-rules.mk

setup-install: 
#	Installs locally the online setup doc
	gdocget -o docs/setup/setup.pdf https://docs.google.com/presentation/d/1ti_VPB0LYcZ46b3NMlDWuwPrZCw0wy7T6IWbk5g_L8Y/edit
	for p in 3 4 5 ; do pdftk docs/setup/setup.pdf cat $p output docs/setup/setup-$p.pdf ; done
#	Generates the setup archive
	docs/setup/build.sh

setup-test:
	docs/setup/test.sh



define package
{
  login: vthierry
  logo: "docs/idnai-logo-ocre.png"
  keywords: [ raspberry esp32 web-service weak-json ]
  dependencies: [ jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor ]
  os: [ Linux armv7l esp32 mingw64 ]
}
endef

include src/makefile-rules.mk

BUILD = setup-build

setup-build: 
#	Builds or updates local setup doc
	bin/gdocget -o docs/setup/setup https://docs.google.com/presentation/d/1ti_VPB0LYcZ46b3NMlDWuwPrZCw0wy7T6IWbk5g_L8Y/edit
	for p in 3 4 5 6 ; do pdftk docs/setup/setup.pdf cat $$p output docs/setup/setup-$$p.pdf ; done
#	Downloads the wJSON.js parser for local use
	bin/urlget https://raw.githubusercontent.com/vthierry/idnai-json/main/docs/wJSON.js docs/setup/wJSON.js
#	Generates the setup archive
	docs/setup/build_zip.sh
#	Syncs with remote
	git add docs/setup/{setup*.pdf,wJSON.js}
	bin/git_sync



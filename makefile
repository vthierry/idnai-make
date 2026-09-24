
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

setup-build: docs/setup.dir/setup.zip
###	Builds or updates local setup doc
	bin/gdocget -o docs/setup.dir/setup https://docs.google.com/presentation/d/1ti_VPB0LYcZ46b3NMlDWuwPrZCw0wy7T6IWbk5g_L8Y/edit
	for p in 3 4 5 6 ; do pdftk docs/setup.dir/setup.pdf cat $$p output docs/setup.dir/setup-$$p.pdf ; done
###	Downloads the wJSON.js parser for local use
	bin/urlget https://raw.githubusercontent.com/vthierry/idnai-json/main/docs/wJSON.js docs/setup.dir/wJSON.js
###	Syncs with remote
	git add docs/setup.dir/{setup*.pdf,wJSON.js}
	bin/git_sync

##	Generates the setup archive
docs/setup.dir/setup.zip: docs/setup.dir/build_setup_zip src/makefile-rules.mk
	docs/setup.dir/build_setup_zip




define package # This defines the package metadata in weak-json syntax
{
  login: vthierry
  logo: "docs/idnai-logo-ocre.png"
  keywords: [ weak-json, esp32, raspberry, web-service ]
  dependencies: [ jsdoc docdash js-beautify idnai-json ]
  os: [ Linux, armv7l, esp32, mingw64 ]
}
endef

define tasks # This is the local short-term shared issues, bug or caveat reports, and todo list in weak-markdown syntax.

  - Documenter introduction.md pour readme

  - Utiliser https://ajv.js.org/json-schema.html#draft-07 pour les types de donnée et en créer d´autres
  - Petit script javascript qui génère un menu du makefile dans une page web avec un système serveur pour finalement tout valider

endef

include ./etc/node_modules/idnai-make/src/makefile-rules.mk

all:
	echo OK


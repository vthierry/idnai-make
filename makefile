
define package # This defines the package metadata in weak-json syntax
{
  name: idnai-make
  description: "The idnai “i dont need A.I.” make package for an agnostic, parsimonious, self-evident, coding framework."
  keywords: [ weak-json, esp32, raspberry, web-service ]
  homepage: https://vthierry.github.io/idnai-make
  version: 0.0.1
  license : [
    { type: CeCILL-C url: https://en.wikipedia.org/wiki/CeCILL for: source-code }
    { type: CC-BY url: https://creativecommons.org/licenses/by/4.0/legalcode for: [ documents multimedia ] }
  ]
  contributors: [
    { name: "Thierry Viéville" mail: thierry.vieville@gmail.com url: https://github.com/vthierry }
  ]
  repository: { type: git url: https://github.com/vthierry/idnai-make }
  bugs: { url: https://github.com/vthierry/idnai-make/issues }
  dependencies: { jsdoc docdash js-beautify india-json }
  os: [ Linux, armv7l, esp32, mingw64 ]
  download: [
    "As an idnai package: `make install=idnai-make`"
    "As a npm package: `npm install idnai-make/git+git@github.com:vthierry/idnai-make.git`"
  ]
}
endef

define tasks # This is the local short-term shared issues, bug or caveat reports, and todo list in weak-markdown syntax.
  - Prévoir page en gison et HTML
  - NommNoer wjson gison
  - Make Usage génère quelque chose en forme de gison mais facilement lisible
  - Juste appeler idnai-json et le créer immédiatement avec juste src/wJSON et les bin/hhh2kkk 
  - Utiliser https://ajv.js.org/json-schema.html#draft-07 pour les types de donnée et en créer d'autres
	-> Mettre braincraft_tex sous overleaf
		organiser les répertoires ./tex comme un push/pull avec un .gitignore et appliquer a braincraft
 - sync avec sous repertoire git aussi : 
 - s'incrire sur abata et organiser le mécanisme à travers le git qui pull/push
 - enlever les github des anciens latex overleaf
 - Petit script javascript qui génère un menu du makefile dans une page web avec un système serveur pour finalement tout valider
endef

include ./etc/node_modules/idnai-make/src/makefile-rules.mk

all:
	echo OK

# init: mkdir -p ./etc/node_modules/ ; cd ./etc/node_modules/ ; ln -s ../.. $name
# install: regarde si local dans le sketchbook=".." si oui crée un lien, sinon cherche sur github ds les contributeurs [ vthierry ] etc… sinon dans npm … if npm show $package-name &>/dev/null ; then npm install $name@latest ; else echo ko ; fi ... sinon propose apt install


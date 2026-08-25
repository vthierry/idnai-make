#!/bin/bash

sandbox="/tmp/snadox-$$"
d="`dirname $0`" ; sketchbook="`realpath $d/../../..`"

/bin/rm -rf $sandbox ; mkdir $sandbox ; cd $sandbox 
cp $sketchbook/idnai-make/.gitignore .
mkdir -p {bin,docs,src,node_modules}
cp -r $sketchbook/idnai-{make,json} node_modules
/bin/rm -rf node_modules/idnai-{make,json}/{.git,node_modules}
cat > makefile~ <<EOF
## The package metadata

define package #=> This defines the GitHub package metadata in json5 syntax (see Notes below).
{
  login: @login #=> The mandatory GitHub account login name responsible for the package
#  logo: "docs/logo-file-name.jpg" #=> An optional logo thumbnail
#  keywords: [ idnai open-source ] #=> An optional list of tags describing the package and its context.
#  version: 0.0.1 #=> The version to be incremented along the developments, if none, set to '0.0.1'.
#  licenses: [ #=> The package licenses, these are the default licenses.
#    { type: CeCILL-C url: https://en.wikipedia.org/wiki/CeCILL for: source-code }
#    { type: CC-BY url: https://creativecommons.org/licenses/by/4.0/legalcode for: [ documents multimedia ] }
#  ]
#  contributors: [ #=> The contributors name (real name, no pseudo), mail and/or url (one mandatory by contract for contact), plus role.
#    { name: "J. Doe" mail: someone@somewhere.com url: https://github.com/\$login role: developer }
#  ]
#  os: [ Linux, armv7l, esp32, Darwin, mingw64 ] # An optional list of targeted operating-systems.
  dependencies: [ idnai-make ] # The other packages required to run this one, if not present 'idnai-make' is added.
}
endef

### Notes:
###
### - These metadata automatically generates the README.md and package.json files, given a GitHub \$login:
###    - The \$name, \$description, \$homepage, \$repository, \$issues and GitHub \$contributor information (as "responsible") are generated:
###      - name: Obtained from this directeory basename.
###      - description: Obtained from GitHub https://github.com/\$login/\$name.
###      - homepage: https://\$login.github.io/\$name #=> Documentation (presentation, user guide, …).
###      - repository: { type: git url: https://github.com/\$login/\$name }
###      - issues: { url: https://github.com/\$login/\$name/issues }
###      - contributors: [ { name: "\$real-name" mail: \$the-mail url: https://github.com/\$login role: responsible } … Obtained from GitHub
###    - Otherwise they must be manually specified.
###
### - Dependencies can be:
###   - Specified by a \$dependency name when:
###     - In this package sketchbook, i.e., in the parent directory of this package.
###     - On the https://github.com/\$login/\$dependency personal repository.
###     - On the public https://www.npmjs.com platform, considering always the latest version.
###     - An 'idnai-*' name.
###   - Specified by a Git URL, if elsewhere.
###     - For instance a 'git+https://github.com/\$another-login/\$another-name' repository.
###     - If on GitHub it can the abbreviated as '\$another-login/\$another-name'.
###
### - The operating-system list is useful to better specify the package target.
###   - It uses 'uname -s' (e.g., 'armv7l' for RaspberryPi, 'Darwin' for MacOS Linux layer, 'mingw64' for windows Linux layer).
###
### - When done, these installation comments and notes can be cleaned.
###

## A notepad area to freely write local todo list, short-term shared issues, bug or caveat reports, and todo list in weak-markdown syntax..
define notepad
  - Something to do.
  - A idea noted here to avoid forgetting. 
endef

## Defines package specific target, if any, and include all framework rules.

INSTALL = 
BUILD = 
TEST = 

ifneq (,\$(ls node_modules/*/src/makefile-rules.mk))
include node_modules/*/src/makefile-rules.mk
endif

## Package specific rules are defined below:

nothing:
	echo "Nothing is more that not anything"

EOF
zip -9qr $sketchbook/idnai-make/docs/setup/setup.zip * .*
/bin/rm -rf $sandbox
cd $sketchbook/idnai-make/docs/setup
git add setup.zip


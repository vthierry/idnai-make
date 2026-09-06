#!/bin/bash

## Used functions

confirm() {
  read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo "$exit_message" ; exit 1 ; fi ; false ; fi
}

urlget() {
  nodejs -e "const fs = require('fs'); fetch('$1', { method: 'GET', headers: { 'Content-Type': 'application/octet-stream', }, responseType: 'arraybuffer'}).then((r) => { return r.arrayBuffer(); }).then((b) => { fs.writeFile(output, Buffer.from(b)); })";
}

if [ -z "$BROWSER" ]
then
 for b in chromium firefox google-chrome brave opera
 do if which -s b ; then export BROWSER=$b ; break ; fi
 done
fi

openurl() { echo "Opening the $1 page" ; $BROWSER "$2" }

## Setup dialog

confirm "This script will set up an idnai-* driven package, is it OK" "OK. Bye."

if confirm "Are you in your sketchbook directory"
then
  read -p "What is, please, your GitHub login: " -e login
  read -p "What is, please, the package name: " -e name
  ok="`nodejs -e 'fetch(\"https://github.com/$login/$name\").then((r) => { if (r.ok) console.log("ok") });'`"
  if [ -z "$ok" ] ; then cat <<EOF
Sorry https://github.com/$login/$name does not exist:
 - The package repository has to be created on GitHub first.
 - You login '$login' or the package name '$name' may be wrong.
Please check and rerun. Bye.
EOF
    openurl "GitHub repository creation" "https://vthierry.dithub.io/idnai-make/docs/setup/setup-3.pdf"
    exit
  fi
  echo "[0/4] Installing useful packages, using sudo …"
  if ! dpkg-query -Wf'${db:Status}' nodejs 2>/dev/null ; then sudo apt install nodejs ; fi
  npm_packages_to_install=""
  for d in jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor http-server
  do if not npm list --depth 1 --global $p > /dev/null 2>&1 ; then npm_packages_to_install="$npm_packages_to_install $p" ; fi
  done
  if [ \! -z "$npm_packages_to_install" ] ; then sudo npm install -g $npm_package_to_install --silent; fi
  sudo npm update -g --silent

  echo "[1/4] Cloning your repository, using ssh …"
  backup "$name" -v
  git clone git@github.com:$login/$name.git

  echo "[2/4] Installing a few useful files …"
  if [ \! -f "node_modules/idnai-make" ]
  then
    mkdir -p node_modules
    if [ -d "idnai-make" ]
    then
      cd node_modules ; ln -s ../idnai-make
    else
      urlget "https://github.com/vthierry/idnai-make/archive/refs/heads/main.zip"
      unzip idnai-make-main.zip ; rm idnai-make-main.zip 
      mv idnai-make-main node_modules/idnai-make
    fi
  fi
  chmod u-w node_modules
  cd $name
  urlget "https://vthierry.github.io/idnai-make/docs/setup/setup.zip"
  unzip -o setup.zip ; rm setup.zip
  sed "s/@login/$login/" < makefile~ > makefile
  make install
  if [ \! -L "./setup.sh" ] ; then rm ./setup.sh ; ln -s ./node_modules/idnai-make/docs/setup.sh ; fi

  echo "[3/4] Updating the GitHub repository …"
  git add makefile bin docs
  git commit -a -m "setup as an idnai-* driven package"
  git push origin master --force

  echo "[4/4] The next step is for you, to activate the documentation pages …"
  openurl "Activate web page settings" "https://github.com/$login/$name/settings/pages" 
  openurl "Activate web page settings documentation" "https://vthierry.dithub.io/idnai-make/docs/setup/setup-5.pdf" 

### If not in the sketchbook directory, exits with a message.
else cat <<EOF
In that case:
- Choose and/or create sketchbook directory, for instance, '~/sketchbook/'.
- Better move this 'setup.sh' script in it.
- Rerun this script. Bye.
EOF
fi

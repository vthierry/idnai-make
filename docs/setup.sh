#!/bin/bash

## Used functions #########################################################################

confirm() {
  read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo -e "$exit_message" ; exit 1 ; fi ; false ; fi
}

backup() {
  echo "backup $1"
  if [ -f "$1" ] ; then
    if [ "$2" = "-v" ] ; then echo "The file '$1' exists and is renamed appendig a '~' suffix." ; fi
    backup "$1~" ; mv "$1" "$1~"
  fi
}

urlget() {
  nodejs -e "const fs = require('fs'); fetch('$1', { method: 'GET', headers: { 'Content-Type': 'application/octet-stream', }, responseType: 'arraybuffer'}).then((r) => { return r.arrayBuffer(); }).then((b) => { fs.writeFile('$1'.replace(new RegExp('.*/'), ''), Buffer.from(b)); })";
}

if [ -z "$BROWSER" ]
then
 BROWSER=xdg-open
 for b in chromium firefox google-chrome brave opera
 do if which -s $b ; then export BROWSER=$b ; break ; fi
 done
fi

openurl() {
  echo "Opening the $1 page" ; $BROWSER "$2"
}

## Setup dialog #########################################################################

confirm "This script will set up an idnai-* driven package, is it OK" "Bye."

confirm "Are you in your sketchbook directory" "In that case:\n- Choose and/or create sketchbook directory, for instance, '~/sketchbook/'.\n- Move this 'setup.sh' script in it.\n- Rerun this script.\nBye."

read -p "What is, please, your GitHub login: " -e login
read -p "What is, please, the package name: " -e name

if [ -z "`nodejs -e \"fetch('https://github.com/$login/$name', { method: 'HEAD' }).then((r) => { if (r.ok) console.log('ok') });\"`" ]
then
  cat <<EOF
Sorry https://github.com/$login/$name does not exist:
 - The package repository has to be created on GitHub first.
 - You login '$login' or the package name '$name' may be wrong.
Please check and rerun.
Bye.
EOF
  openurl "GitHub repository creation" "https://vthierry.github.io/idnai-make/setup/setup-3.pdf"
  exit 1
fi

echo "[0/4] Installing useful packages, using sudo …"
if ! dpkg-query -Wf'${db:Status}' nodejs 2>/dev/null ; then sudo apt install nodejs ; fi
npm_packages_to_install=""
for p in jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor http-server
do if ! npm list --depth 1 --global $p 2>&1 > /dev/null ; then npm_packages_to_install="$npm_packages_to_install $p" ; fi
done
if [ \! -z "$npm_packages_to_install" ] ; then sudo npm install -g $npm_package_to_install --silent ; fi
sudo npm update -g --silent

echo "[1/4] Cloning your repository, using ssh …"
backup $name -v
git clone git@github.com:$login/$name.git

echo "[2/4] Installing a few useful files …"
### The global sketchbook/node_modules/idnai-make
if [ \! -f node_modules/idnai-make ]
then
  mkdir -p node_modules
  if [ -d idnai-make ]
  then
    cd node_modules ; ln -s ../idnai-make ; cd ..
  else
    urlget "https://github.com/vthierry/idnai-make/archive/refs/heads/main.zip"
    unzip idnai-make-main.zip ; rm idnai-make-main.zip 
    mv idnai-make-main node_modules/idnai-make
  fi
fi
if [ \! -L setup.sh ] ; then rm setup.sh ; ln -s node_modules/idnai-make/docs/setup.sh ; fi
## The package default files
cd $name
urlget "https://vthierry.github.io/idnai-make/setup/setup.zip"
unzip -o setup.zip ; rm setup.zip
sed "s/@login/$login/" < makefile~ > makefile
make install

echo "[3/4] Updating the GitHub repository …"
git add makefile bin docs
git commit -a -m "setup as an idnai-* driven package"
git push origin master --force

echo "[4/4] The next step is for you, to activate the documentation pages …"
openurl "Activate web page settings" "https://github.com/$login/$name/settings/pages" 
openurl "Activate web page settings documentation" "https://vthierry.github.io/idnai-make/setup/setup-6.pdf" 

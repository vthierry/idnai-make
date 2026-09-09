#!/bin/bash

## Used functions #########################################################################

confirm() {
  read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo -e "$exit_message" ; exit 1 ; fi ; false ; fi
}

backup() {
  if [ -e "$1" ] ; then
    if [ "$2" = "-v" ] ; then echo "The file '$1' exists and is renamed appendig a '~' suffix." ; fi
    backup "$1~" ; mv "$1" "$1~"
  fi
}

urlget() {
  if ! nodejs -e "const fs = require('fs'); fetch('$1', { method: 'GET', headers: { 'Content-Type': 'application/octet-stream' }, responseType: 'arraybuffer'}).then(r => { if (r.ok) return r.arrayBuffer(); else { console.error('Unable to reach $1: are you connected and is https://github.com online ?'); process.exit(1); } }).then(b => { fs.writeFile('$1'.replace(new RegExp('.*/'), ''), Buffer.from(b), e => { }); })" ; then exit 1; fi
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
#if ! dpkg-query -Wf'${db:Status}' nodejs 2>/dev/null ; then sudo apt install nodejs ; fi
#for p in jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor http-server
#do if ! npm list --depth 1 --global $p 2>&1 > /dev/null ; then sudo npm install $p --global --silent ; fi
#done
#sudo npm update --global --silent

echo "[1/4] Cloning your repository, using ssh …"
#backup $name -v
#git clone --quiet git@github.com:$login/$name.git 2>&1 | grep -v 'warning:.*empty repository'

echo "[2/4] Installing a few useful files …"
### The global sketchbook/node_modules/idnai-make
if [ \! -d ./node_modules/idnai-make ]
then
  if [ \! -d idnai-make ]
  then
    urlget "https://github.com/vthierry/idnai-make/archive/refs/heads/main.zip"
    unzip idnai-make-main.zip ; rm idnai-make-main.zip 
    mv idnai-make-main ./node_modules/idnai-make
  fi
fi
make -C ./node_modules/idnai-make install
if [ \! -L setup.sh ] ; then rm setup.sh ; ln -s ./node_modules/idnai-make/docs/setup.sh ; fi
## The package default files
cd $name
urlget "https://vthierry.github.io/idnai-make/setup/setup.zip"
unzip -q -o setup.zip ; rm setup.zip
sed "s/@login/$login/" < makefile~ > makefile
exit
make install

echo "[3/4] Updating the GitHub repository …"
git add makefile bin docs
git commit --quiet -a -m "setup as an idnai-* driven package"
git push --quiet origin master --force

echo "[4/4] The next step is for you, to activate the documentation pages …"
openurl "Activate web page settings" "https://github.com/$login/$name/settings/pages" 
openurl "Activate web page settings documentation" "https://vthierry.github.io/idnai-make/setup/setup-6.pdf" 

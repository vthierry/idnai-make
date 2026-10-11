#!/bin/bash

<<<<<<< HEAD
=======
<<<<<<< HEAD
=======
<<<<<<< HEAD:docs/setup.sh
>>>>>>> e4d850903a6aa3e034a6ff724a8d47524d62533a
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
## Version 

confirm() { # Usage: confirm $message [$exit_message] ; Asks a true/false question ; returns the boolean answer ; exits if false, with $exit=y.
    read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo "$exit_message" ; exit ; fi ; false ; fi
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
}
needfor() { # Usage: needfor package ; Tests if a package is installed before used, and proposes to install otherwise.
  if ! dpkg-query -Wf'${db:Status}' "$1" 2>/dev/null ; then
    if confirm "The '$1' package is not installed ? Shall we" "It cannot be proceeded, bye." ; then sudo apt install "$1" ; fi
  fi
}
<<<<<<< HEAD
=======
=======
=======
# Present usage: setup ; Sets up an idnai-* driven package from scratch

## Used functions #########################################################################

confirm() {
  read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo -e "$exit_message" ; exit 1 ; fi ; false ; fi
>>>>>>> fd2c3c97569b848b31df839804b749fed0f4c1eb:docs/setup
}

bakfile() {
  if [ -e "$1" ] ; then
    if [ "$2" = "-v" ] ; then echo "The file '$1' exists and is renamed appendig a '~' suffix." ; fi
    bakfile "$1~" ; mv "$1" "$1~"
  fi
}
<<<<<<< HEAD:docs/setup.sh
>>>>>>> e4d850903a6aa3e034a6ff724a8d47524d62533a
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
backup() { # Usage: backup file [-v|--verbose] ; Backups a file if it exists, appending a '~' suffix.
  if [ -f "$1" ] ; then
    if [ \! -z "$2" ] ; then echo "The file '$1' exists and is renamed appendig a '~' suffix." ; fi
    backup "$1~"
    mv "$1" "$1~"
  fi
<<<<<<< HEAD
=======
<<<<<<< HEAD
=======
=======

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
  echo -e "$1" ; $BROWSER "$2" >/dev/null
>>>>>>> fd2c3c97569b848b31df839804b749fed0f4c1eb:docs/setup
>>>>>>> e4d850903a6aa3e034a6ff724a8d47524d62533a
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
}
if [ -z "$BROWSER" ]
then
 for b in chromium firefox google-chrome brave opera
 do if which -s b ; then export BROWSER=$b ; break ; fi
 done
fi
openurl() { # Usage: open url [title] ; Opens a web page for the user, with an optional 'Opening the $title page' message.
  if [ \! -z "$2" ] ; then echo "Opening the $2 page" ; fi
  $BROWSER "$1"
}

<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
confirm "This script will setup an idnai-* driven package, is it OK" true

needfor nodejs

if confirm "Are you in your scketchbook directory"
then
<<<<<<< HEAD
=======
=======
## Setup dialog #########################################################################

confirm "This script will set up an idnai-* driven package, is it OK" "Bye."

### This script is only usable in a sketchbook directory
confirm "Are you in your sketchbook directory" "In that case:\n- Choose and/or create sketchbook directory, for instance, '~/sketchbook/'.\n- Move this 'setup' script in it.\n- Rerun this script.\nBye."

### This script only applies to GitHub repository
read -p "What is, please, your GitHub login: " -e login
read -p "What is, please, the package name: " -e name

if [ -z "`nodejs -e \"fetch('https://github.com/$login/$name', { method: 'HEAD' }).then((r) => { if (r.ok) console.log('ok') });\"`" ]
then
<<<<<<< HEAD:docs/setup.sh
>>>>>>> e4d850903a6aa3e034a6ff724a8d47524d62533a
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
  read -p "What is, please, the your GitHub login: " -e login
  read -p "What is, please, the package name: " -e name
  ok="`nodejs -e 'fetch(\"https://github.com/$login/$name\").then((response) => { if (response.ok) console.log("ok") });'`"
  if [ -z "$ok" ] ; then cat <<EOF
Sorry https://github.com/$login/$name does not exist:
 - The package repository has to be created on GitHub first.
 - You login '$login' or the package name '$name' may be wrong.
Please check and rerun. Bye.
EOF
    openurl "https://vthierry.dithub.io/idnai-make/docs/setup/setup-1.pdf" "GitHub repository creation"
    exit
  fi
  backup "$name" -v
  echo "[1/4] Cloning your repository, using ssh …"
  git clone git@github.com:$login/$name.git
  echo "[2/4] Installing a few useful files …"
  cd $name
  nodejs -e 'fetch("https://vthierry.github.io/idnai-make/docs/setup/setup.zip");'
  unzip -o setup.zip ; rm setup.zip
  sed "s/@login/$login/" < makefile~ > makefile
  make install
  if [ \! -L "./setup.sh" ] ; then rm ./setup.sh ; ln -s $name/node_modules/idnai-make/docs/setup.sh ; fi
  echo "[3/4] Updating the GitHub repository"
  git add makefile bin docs
  git commit -a -m "setup as an idnai-* driven package"
  git push origin master --force
  echo "[4/4] Next step is for you, to activate the documentation pages …"
  openurl "https://vthierry.dithub.io/idnai-make/docs/setup/setup-3.pdf" "Activate documentation"
  openurl "https://github.com/$login/$name/settings/pages" "Activate web page settings"
else cat <<EOF
In that case:
- Choose and/or create scketchbook directory, for instance, '~/scketchbook/'.
- Better move this 'setup.sh' script in it.
- Rerun this script. Bye.
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea
EOF
fi


  
<<<<<<< HEAD
=======
=======
=======
  cat <<EOF
Sorry https://github.com/$login/$name does not exist:
 - The package repository has to be created on GitHub first.
 - You login '$login' or the package name '$name' may be wrong.
Please check and rerun.
Bye.
>>>>>>> fd2c3c97569b848b31df839804b749fed0f4c1eb:docs/setup
EOF
  openurl "GitHub repository creation" "https://vthierry.github.io/idnai-make/setup.dir/setup-3.pdf"
  exit 1
fi

<<<<<<< HEAD:docs/setup.sh

  
=======
### This script requires nodejs
if ! dpkg-query -Wf'${db:Status}' nodejs 2>/dev/null ; then sudo apt install nodejs ; fi

## Setup steps #########################################################################

echo "[1/4] Cloning your repository, using ssh …"
bakfile $name -v
git clone --quiet git@github.com:$login/$name.git

echo "[2/4] Installing a few useful files …"
if [ -f $0.dir/setup.zip ]
then cp $0.dir/setup.zip .
else urlget "https://vthierry.github.io/idnai-make/setup.dir/setup.zip"
fi

cd $name

unzip -q -o ../setup.zip ; /bin/rm ../setup.zip
sed "s/@login/$login/" < makefile~ > makefile ; /bin/rm makefile~

make install

echo "[3/4] Updating the GitHub repository …"
git add .gitignore makefile bin docs src
git commit --quiet -a -m "setup as an idnai-* driven package"
git push --quiet --force

cd ..

echo "[4/4] Next step: please, manually activate the web pages:"
#@ openurl "\tIn the Pages settings" "https://github.com/$login/$name/settings/pages" 
#@ openurl "\tUsing the related documentation" "https://vthierry.github.io/idnai-make/setup.dir/setup-6.pdf" 
>>>>>>> fd2c3c97569b848b31df839804b749fed0f4c1eb:docs/setup
>>>>>>> e4d850903a6aa3e034a6ff724a8d47524d62533a
>>>>>>> 4b91f2749361c69388f81f1e0a3c50a44e71e0ea

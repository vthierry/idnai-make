#!/bin/bash

## Version 

confirm() { # Usage: confirm $message [$exit_message] ; Asks a true/false question ; returns the boolean answer ; exits if false, with $exit=y.
    read -p "$1? (y/N) : " -n 1 -e rep ; if [ "$rep" = "y" ] ; then true ; else if [ \! -z "$exit_message" ] ; then echo "$exit_message" ; exit ; fi ; false ; fi
}
needfor() { # Usage: needfor package ; Tests if a package is installed before used, and proposes to install otherwise.
  if ! dpkg-query -Wf'${db:Status}' "$1" 2>/dev/null ; then
    if confirm "The '$1' package is not installed ? Shall we" "It cannot be proceeded, bye." ; then sudo apt install "$1" ; fi
  fi
}
backup() { # Usage: backup file [-v|--verbose] ; Backups a file if it exists, appending a '~' suffix.
  if [ -f "$1" ] ; then
    if [ \! -z "$2" ] ; then echo "The file '$1' exists and is renamed appendig a '~' suffix." ; fi
    backup "$1~"
    mv "$1" "$1~"
  fi
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

confirm "This script will set up an idnai-* driven package, is it OK" "OK. Bye."

needfor nodejs

npm_packages_to_install=""
for d in jsdoc docdash js-beautify markdown-it markdown-it-table-of-contents markdown-it-anchor http-server express
do if not npm list --depth 1 --global $p > /dev/null 2>&1 ; then npm_packages_to_install="$npm_packages_to_install $p" ; fi
done
if [ \! -z "$npm_packages_to_install" ] ; then
  if confirm "Shall we install globally these usual npm packages '$npm_packages_to_install' to save place and time" ; then
    sudo npm install -g $npm_package_to_install
fi fi 

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
    openurl "https://vthierry.dithub.io/idnai-make/docs/setup/setup-3.pdf" "GitHub repository creation"
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
  echo "[3/4] Updating the GitHub repository …"
  git add makefile bin docs
  git commit -a -m "setup as an idnai-* driven package"
  git push origin master --force
  echo "[4/4] The next step is for you, to activate the documentation pages …"
  openurl "https://vthierry.dithub.io/idnai-make/docs/setup/setup-5.pdf" "Activate documentation"
  openurl "https://github.com/$login/$name/settings/pages" "Activate web page settings"
else cat <<EOF
In that case:
- Choose and/or create scketchbook directory, for instance, '~/scketchbook/'.
- Better move this 'setup.sh' script in it.
- Rerun this script. Bye.
EOF
fi

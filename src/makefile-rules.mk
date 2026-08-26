# These are the idnai makefile rules

## Configures the makefile with bash, in silent mode, avoiding spurious parallelism, and extending path.

export SHELL := /bin/bash

THE_MAKEFILES = makefile $(wildcard node_modules/*/src/makefile-rules.mk)

.SILENT: $(shell cat $(THE_MAKEFILES) | sed -n 's/^\([^:]*\):.*/\1/p')

.NOTPARALLEL:

export PATH := $(PWD)/bin $(PWD)/node_modules/.bin $(PATH)

export NAME := $(notdir $(PWD))

### Detects a browser if not yet defined.

ifeq (,$(BROWSER))
BROWSERS = chromium firefox google-chrome brave opera
export BROWSER = $(shell l=($(foreach b,$(BROWSERS),$(shell if which -s $(b) ; then echo $(b) ; fi))) ; echo $${l[0]})
endif

## Detects rules with parameters if any, else shows usage.

what := $(strip $(foreach t, install sync start show stop test build, $(if $($(t)),$(t) $(t)=$($(t)),)))

default:
	$(MAKE) $(if $(what),$(what),usage)

## Shows the makefile usage, extracting automatically the documentation.

## - General elements:
##   - Please refer to the [make](https://www.gnu.org/software/make/manual/make.html) documentation.
##   - Auto-documented makefile:
##     - Target's construct of pattern 'target: dependencies # [options] Description' yield the usage.
##     - Lines of pattern '## - Complements' completes the usage in the documentation.
##   - With [`make -d [option]`](https://www.gnu.org/software/make/manual/html_node/Options-Summary.html#index-_002dd)
##     - Various debugging information are available.
##     - If recompiled, the C/C++ `DEBUG` global variable is set.

usage: # Shows this usage
	echo 'Usage: make $$command [$$arguments] Available commands:'
	cat $(THE_MAKEFILES) | sed  -n 's/^\([a-z_0-9]*\):[^#]*#/  - \1/p' | sed 's/ *[[]/[/' ; ok=

## Installation operations

INSTALL += node_modules/$(NAME) README.md 

install: $(INSTALL) # [=$package] Installs or updates, a given packages or all packages.	
	chmod -R u+w node_modules package.json package-lock.json
	npm install --silent $(install)
	chmod -R a-w node_modules package.json package-lock.json

## - Disclaimer: do NOT use `npm target` directly but `make target`.
## - Generates the README.md, package.json, and other installation file, and install what is needed.
## - Hint: The INSTALL variable can be defined in makefile for package specific targets.
## - Note: a link of the present package is created in node_modules for homogeneity.

node_modules/$(NAME):
	chmod u+w -R node_modules
	mkdir -p $@ ; cd $@ ; ln -s ../../* ; rm node_modules

README.md: makefile
	node_modules/idnai-make/docs/setup/makefile2readmetc

## Manages build rules

build: # [=hostname[/path]] Builds targets defined by the makefile rules, locally or on an accessible host, path=~/sketchbook by default.
	if [ -z "$(build)" ] ;\
	then $(MAKE) $(BUILD) ;\
	else \
	  $(MAKE) sync ;\
	  if [ "$(notdir ($build))" = "$(build)" ] ;\
	  then d="~/sketchbook" ;\
	  else d="$(notdir ($build))" ;\
	  fi ;\
	  ssh "`echo '$(build)' | sed 's/\/.*//g'`" -c "cd $$d/$(NAME) ; make sync build sync" ;\
	fi

## - Partial installation policy:
##   - If a software is missing, the rule is silently ignored, assuming it is processed from another checkout.
## - Hint: The BUILD variable can be defined in makefile for package specific targets.

### Properly renders the markdown files (with the @frame tag, if any).

docs/%.html: src/%.md
	node_modules/idnai-make/bin/subst "@frame\\s+([^\\s]+)" "<p><center><iframe style='width: 100%; height: calc(66vh);' src='$1'></iframe></center><a href='$$1' target='_blank'>&nbsp;&nbsp;(open in new tab)</a></p>" $^ |\
	node_modules/idnai-make/bin/md2html > $@

### Defines the API documentation and markdown file's rendering generation

BUILD_API = beautify $(subst src/%.md,docs/%.html,$(wildcard *.md)) docs/index.html linkcheck

### - Building API documentation:
###   - Documentation is found in src/*.md, */*.js, */*.hpp, */*.mpl, and bin/* files.
###   - Source file are beautified yielding a standard layout.
###   - The src/introduction.md content and the ./makefile metadata yield the home page.
###   - Other markdown documentation is converted to docs/*.html files.
###   - Implementation details:
###     - It uses [jsdoc](https://jsdoc.app) for all sources, but Python ones, with a variant of the [docdash](https://www.npmjs.com/package/docdash) template.
###   - Script usage documentation:
###     - Bash script usage is by contract implemented in a 'cat <<EOU\nUsage: … \nEOU' construct.
###     - Node script usage is by contract implemented in a 'console.log(`\nUsage: … \n`);' construct.
###     - In both cases the syntax is of the form 'Usage: $function_name $arguments\n$one_line_description\n$more_description'.
###   - Documentation usage:
###     - Classes with lower-case 1st letter are documented as "factory", i.e., set of static methods.
###     - The `@extends` tag must be inserted _after_ the `@description`, to generate the proper layout.
###     - The `@frame $file`: inserts a iframe displaying the given file.
###     - Script one-line usage format is "Usage: $command $arguments ; $description"
###     - Non JavaScript source file must have all documentation fields explicit, as exemplified [here](https://github.com/vthierry/idnai-json/blob/main/src/wjson.hpp).

#### Normalize the source file layout

beautify:
ifneq (,$(shell which js-beautify))
	for f in $(wildcard */*.js) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; js-beautify -q -s 2 -n -r $$f ; touch $$f -r $$f~ ; done
endif
ifneq (,$(shell which css-beautify))
	for f in $(wildcard */*.css) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; css-beautify -q -s 2 -n -r $$f ; touch $$f -r $$f~ ; done
endif
ifneq (,$(shell which uncrustify))
	for f in $(wildcard src/*.hpp) $(wildcard src/*.cpp) $(wildcard src/*.C) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; uncrustify -q -c node_modules/adnai-make/src/uncrustify.cfg -f $$f~ -o $$f ; touch $$f -r $$f~ ; done ; fi
endif

#### Generates Python documentation if any

ifneq (,$(wildcard src/*.py))

PY_API = true

docs/py/index.html: $(wildcard src/*.py)
	mkdir -p $(@D)
	pdoc --footer-text "`date +'%Y-%m-%d %H:%M:%S'` version"  $^ -o docs/py

endif

#### Installs the docdash template variant.

node_modules/docdash2:
	mkdir -p $@
	cp -rf node_modules/{docdash/{static,tmpl},idnai-make/src/docdash2/{publish.js,bin2doc,mk2doc}} $@
	cp  ./docdash2/docdash2.js node_modules/jsdoc/plugins

#### Converts bin and make usage's documentations in jsdoc one.

node_modules/docdash2/tmp_mk.js: $(THE_MAKEFILES)
	(echo -e "/** @class make\n@description Usage: make \$$command, available commands: */" ;\
	 node_modules/docdash2/mk2doc $^) > $@

node_modules/docdash2/tmp_bin.js : $(wildcard bin/[a-z0-9]*)
	(echo -e "/** @class scripts\n@description Available scripts: */" ;\
	 node_modules/docdash2/bin2doc $^) > $@

#### Runs jsdoc with linkcheck

docs/index.html: README.md node_modules/docdash2 node_modules/docdash2/tmp/makefile.js $(wildcard */*.hpp) $(wildcard */*.js) $(wildcard */*.sh) $(wildcard */*.mpl)
	jsdoc -c node_modules/adnai-make/src/docdash2/config.json -t node_modules/docdash2 -R README.md -d docs node_modules/docdash2/tmp_*.js $(sort $(wildcard *.js))

linkcheck:
	for l in `find docs -name '*.html' -exec grep 'href *=' {} \; | subst "[^\n]*href=['\"]([^'\"]*)['\"][^\n]*" "$$1" | sort -u` ;\
	do if [ -z "`nodejs -e 'fetch(\"$$l\").then((r) => { if (!r.ok) console.log(\"ok\") });'" ] ;\
	then echo "Broken link: $$l" ;\
	fi done

### Defines maple processing for file generation.

### - Generating code and drawings from computer algebra:
###   - Batch [maple](https://www.maplesoft.com) `*/*.mpl` files are processed.
###     - This allows to generate figures or other tex elements.
###     - A `*/*.mpl.out.txt` output is produced.
###       - This file contains errors if any, otherwise the maple process trace.
###     - The [idnai-sys](https://github.com/vthierry/idnai-sys) package shares useful functions.
###   - If [maple](https://www.maplesoft.com) is not available locally,
###     - A `build=host` command on an ssh available host with another checkout and maple installed makes the job.
###   - Typical usage is:
###     - Piece of code generation translated from algebra derivation, e.g. using the [maple2h](https://vthierry.github.com/idnai-sys/maple2h.html) function.
###     - Graphics defined in the maple source, e.g. using the [maple2jpg](https://vthierry.github.com/idnai-sys/maplejpg) function.
###     - LaTeX formulas or piece of text files, programmed in the maple source, e.g. using the [latex](https://www.maplesoft.com/support/help/Maple/view.aspx?path=latex) function.

### Applies maple on maple souce file keeping trace locally of the output.

ifneq (,$(shell which maple))
%.mpl.out.txt: %.mpl
	cd $(@D) ; maple ../$^ > ../$@
	git add $@
endif

### Defines latex and related files compilation.

### - Building complementary documentation:
###   - [LaTeX](https://www.latex-project.org) document or presentation:
###     - Input latex files are `tex/*.tex` or `src/*.tex` with a \documentclass header.
###     - Output latex files are `docs/*.pdf`.
###     - The `beamer` package is recommended for slides.
###   - Drawings built with [libreoffice](https://fr.libreoffice.org) `tex/*.odg are processed as `tex/*.png`.
###   - Drawings built with [maple](https://www.maplesoft.com) `*/*.mpl` files are also taken into account.

LATEX_MAINS = $(foreach f,$(wildcard */*.tex),$(if $(shell head -1 $(f) | grep '\\documentclass'),$(f),))
BUILD_LATEX = $(patsubst %.odg,%.png,$(wildcard %/*.odg)) $(patsubst %.mpl,%.mpl.out.txt,$(wildcard %/*.mpl)) $(patsubst tex/%.tex,docs/%.pdf,$(patsubst src/%.tex,tex/%.tex,$(LATEX_MAINS)))

### Applies pdflatex with the proper options and cleans all temporary unused files.

ifneq (,$(shell which pdflatex))
docs/%.pdf: tex/%.tex $(wildcard tex/*.bib) $(filter-out $(LATEX_MAINS),$(wildcard tex/*.tex))
	cd tex; pdflatex -halt-on-error -draftmode $* ; bibtex $* ; pdflatex -halt-on-error -draftmode $* ; pdflatex -halt-on-error $* ; grep -i undefined $*.log ; rm -f $*.aux $*.bbl $*.blg $*.toc $*.nav $*.snm $*.out ; ok=
	mv tex/$*.pdf $@ 
	git add $@

docs/%.pdf: src/%.tex $(wildcard src/*.bib) $(filter-out $(LATEX_MAINS),$(wildcard src/*.tex))
	cd src; pdflatex -halt-on-error -draftmode $* ; bibtex $* ; pdflatex -halt-on-error -draftmode $* ; pdflatex -halt-on-error $* ; grep -i undefined $*.log ; rm -f $*.aux $*.bbl $*.blg $*.toc $*.nav $*.snm $*.out ; ok=
	mv src/$*.pdf $@ 
	git add $@
endif

### Compiles libreoffice drawings.

ifneq (,$(shell which libreoffice))
%.png : %.odg
	libreoffice --headless --convert-to png --outdir $(@D) $^
	git add $@
endif

### Defines C++ compilation rules

### - Building C/C++ library and executable.
###   - On input:
###     - Headers and documentation are .hpp files.
###     - Object implementation are in .cpp files.
###     - Main programs are in .C files.
###     - Any available maple batch file is processed, for code generation.
###     - Any src/%_hpp.html file generates a src/%.hpp file with the web page as constant C/C++ string.
###   - For compilation:
###     - The `clang`, `g++`, or `c++` in this order, if available.
###     - The include path considers all `node_modules/*/src` directories.
###     - The `uname -s` value is set as the OS variable.
###     - A maximal number of warning, debug information, and optimisation is performed.
###     - Actually the `-std=c++17` C++ standard is in use.
###   - On output:
###     - All compiled objects are in `node_modules/libcpp.so`.
###     - All executable program are in `node_modules/.bin/%` files.
###   - Hints:
###     - With `make -d …` the DEBUG global variable is set.
###     - Undefined symbols defined in a .hpp fils but not implemented in a .cpp file appears using
###       - `nm -C --demangle --undefined-only ../node_modules/libcpp.so | grep $name`

CCP = $if($(which clang),clang,$if($(which g++),g++,$if($(which c++),c++,)))

ifneq (,$(CPP))

OS=$(shell uname -s) 

CPP_FLAGS = -g -fPIC -Wall -std=c++17 -O3 -D OS=$(OS) \
 $(patsubst %,-I%,$(wildcard node_modules/*/src) $(wildcard /usr/include/python3.*) /usr/local/Frameworks/Python.framework/Headers)

ifeq (-d,$(findstring -d,$(MAKEFLAGS)))
CPP_FLAGS += -D DEBUG
endif

BUILD_CPP = $(patsubst %.mpl,%.mpl.out.txt,$(wildcard node_modules/*/src/*.mpl)) $(patsubst %_hpp.html,%.hpp,$(wildcard node_modules/*/src/*_hpp.html)) $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp)) node_modules/libcpp.so $(patsubst src/%.C,bin/%,$(wildcard node_modules/*/src/*.C)) 

#### Automatic headers generation

%.hpp: %_hpp.html
	@(echo -n "static char $*[] = \"" ; tr "\n" " " < $^ | sed 's/"/\\"/g' | sed 's/  */ /g' ; echo "\";") > $@

#### Source object compilation

%.o: %.cpp
	$(CPP) -c $(CPP_FLAGS) $^

node_modules/libcpp.so : $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp))
	$(CPP) -o $@ -fPIC -shared $^

CPP_LIBS = node_modules/libcpp.so -lstdc++ -lm $(shell find /usr/lib -name 'libpython3.*.so' | head -1)
ifneq (mingw64,$(OS))
CPP_LIBS  += -lcurl
endif

node_modules/.bin/%: src/%.C
	$(CPP) -o $@ $(CPP_FLAGS) $^ $(CPP_LIBS)

endif

## Tests mechanisms 

test: # [=file] [argv="arg1 …"] Runs a given src/$file file, if specified, or all functional and non-regression src/test.* test files.
	if [ -z "$(test)" ] ; then \
          for e in C sh js py mpl html ; do if [ -f test.$$e ] ; then $(MAKE) test=test.$$e ; fi ; done \
	  if [ \! -z "$(TEST)" ] ; then $(MAKE) $(TEST) ; fi \
        else \
	  switch($(suffix $(test))) { \
	    case 'C' : $(MAKE) $(BUILD_CPP) ; $(MAKE) test=node_modules_/.bin/$(basename $(test)) $(argv) ;;\
	    case 'sh' : case 'js' : chmod a+rx src/$(test) ; ./src/$(test) $(argv) ;;\
            case 'py' : python3 ./src/(test) ;;\
	    case 'mpl' : $(MAKE) ./src/$(test).out.txt ;;\
	    case 'html' : $(BROWSER) $(test) ;;\
	    default: echo "Error: The $(test) extension is not managed." ;; \
         }\
	fi	

## - The `src/test.{C,sh,js,py,mpl,html}` files are managed for functional and non-regression.
## - Hint: The TEST variable can be defined in makefile for package specific targets.

ifneq (,$(which gdb))
gtest: $(BUILD_CPP) # [=file] [argv="arg1 …"] Runs a given CPP file with gdb, for debug.
	if [ -z "$(gtest)" ] ; then test="test" ; else test="$(basename $(gtest))" ; fi \
	unset DEBUGINFOD_URLS ;	(echo "break exit" ; echo "run $(argv)" ; echo "echo --- backtrace ------------------------------------------------------------------------------\n" ; echo "backtrace" ; echo "echo --- backtrace full -------------------------------------------------------------------------\n" ; echo "backtrace full" ; echo "quit 0") > /tmp/a.cmd ;\
	gdb -n -q node_modules_/.bin/$$test -x /tmp/a.cmd --return-child-result 2>&1 ; ok=
else 
	echo "You need to `sudo apt install gdb` for `make gtest`."
endif

ifneq (,$(which valgrind))
vtest: $(BUILD_CPP) # [=file] [argv="arg1 …"] Runs a given CPP file with valgrinddebug.
	if [ -z "$(vtest)" ] ; then test="test" ; else test="$(basename $(vtest))" ; fi \
	ulimit -s 100000 2>/dev/null ; export GLIBCXX_FORCE_NEW=1 ; valgrind --max-stackframe=100000000 --track-origins=yes node_modules_/.bin/$$ $(argv)
else 
	echo "You need to `sudo apt install valgrind` for `make gtest`."
endif

## Builds or cleans all files defined by the previous rules.

BUILD += $(BUILD_API) $(BUILD_LATEX) $(BUILD_CPP) $(BUILD_ESP32)

clean: # Removes all targets defined by the makefile rules.
	node_modules/idnai-make/bin/clean
	/bin/rm -rf $(BUILD)

rebuild: clean build  # Cleans and builds all targets defined by the makefile rules.

## Manages a local http:127.0.0.1 server

start: # [=$port] Starts, if not yet done, a local 'http:127.0.0.1:$port' server, port=8080 by default.
ifneq (,$(shell which http-server))
	if [ \! -z "$(start)" ] ; then port=8080 ; else port="$(start)" ; fi ;\
	if [ "`urlexists http:127.0.0.1:$$port`" -ne 200 ] ;\
	then (cd docs ; nohup http-server -a 127.0.0.1 -p $$port 0</dev/null &>/dev/null &) ;\
	fi
else
	needfor http-server
	$(MAKE) start
endif

show: # [=$port] Shows a local 'http:127.0.0.1:$port' page, port=8080 by default.
	$(MAKE) start=$(show)
	if [ \! -z "$(show)" ] ; then port=8080 ; else port="$(show)" ; fi ;\
	$(BROWSER) http://127.0.0.1:$$port

stop: # [=$port] Stops, if not yet done, a local 'http:127.0.0.1:$port' server, port=8080 by default.
	if [ \! -z "$(stop)" ] ; then port=8080 ; else port="$(stop)" ; fi ;\
	killall http://127.0.0.1:$$port

## - It renders the ./docs directory.

## Force synchronization with respect to git repositories

sync: # [=$message] Synchronizes files with respect to the github repositories.
	node_modules/idnai-make/bin/git_sync $(sync)

## Force synchronization with respect to git repositories

publish: # Publishes on the npmjs repository.
	npm adduser
	npm publish --access-public

## - To publish or update a package on `https://registry.npmjs.org/`
##   - Properly update the [version number](https://docs.npmjs.com/about-semantic-versioning) in the makefile metadata, before `make publish`.
## - To manually archived on [https://archive.softwareheritage.org](https://archive.softwareheritage.org).
##   - Use [this link](https://archive.softwareheritage.org/save/list/) to save it.
##     - Enter `git` in `Origin type`
##     - Enter the documentation link, e.g. `https://github.com/$login}/$name`
##     - And you are done.

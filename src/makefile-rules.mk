# These are the idnai makefile rules
## Note:
## - Partial installation policy: If a software is missing, the rule is ignored, assuming it is processed from another checkout.

## Configures the makefile with bash, in silent mode, avoiding spurious parallelism, and extending path.

export SHELL := /bin/bash

THE_MAKEFILES = makefile $(wildcard node_modules/idnai-*/src/makefile-rules.mk)

.SILENT: $(shell cat $(THE_MAKEFILES) | sed -n 's/^\([^:]*\):.*/\1/p')

.NOTPARALLEL:

export PATH := $(PWD)/bin $(PWD)/node_modules/.bin $(PATH)

export NAME := $(notdir $(PWD))

## Detects rules with parameters if any, else shows usage.

what := $(strip $(foreach t, sync start show stop test build, $(if $($(t)),$(t) $(t)=$($(t)),)))

default:
	$(MAKE) $(if $(what),$(what),usage)

## Shows the makefile usage, extracting all names targets with a line of documentation.

usage: # usage ; Shows the makefile usage.
	echo -e 'Usage: make $$command, available commands:'
	cat $(THE_MAKEFILES) | sed -n 's/^[a-z_0-9]*: *[^#]*# *\(.*\)/   - \1/p' | sort -u
### Note:
### - It is based on target's construct of the form 'target: dependencies # description'.

## Force synchronization with respect to git repositories

sync: # sync[=$message] ; Synchronizes files with respect to the github repositories.
	node_modules/idnai-make/bin/git_sync $(sync)

## Installation operations

BUILD_INSTALL = node_modules/$(NAME) README.md bin/Usages.md 

### Notes:
### - Creates a link of the present package in node_modules, this for homogeneity, when building from sources.
### - Generates the README.md, package.json, and other installation file, and install what is needed.
### - Creates an usage document with all available scripts.

node_modules/$(NAME):
	chmod u+w -R node_modules
	mkdir -p $@ ; cd $@ ; ln -s ../../* ; rm node_modules

README.md: makefile
	node_modules/idnai-make/bin/makefile2readmetc
	chmod -R u+w node_modules package.json package-lock.json
	npm install --silent
	chmod -R a-w node_modules package.json package-lock.json
	cd node_modules/.bin ; ln -sb ../*/bin/* 

bin/Usages.md: $(wildcard bin/[a-z]*)
	chmod a+rx ./bin/[a-z]*
	node_modules/idnai-make/bin/bin2usage

## Manages a local http:127.0.0.1 server

### Notes:
### - It actually renders the ./docs directory

start: # start[=$port] ; Starts, if not yet done, a local http:127.0.0.1:$port server, port=8080 by default..
ifneq (,$(shell which http-server))
	if [ \! -z "$(start)" ] ; then port=8080 ; else port="$(start)" ; fi ;\
	if [ "`urlexists http:127.0.0.1:$$port`" -ne 200 ] ;\
	then (cd docs ; nohup http-server -a 127.0.0.1 -p $$port 0</dev/null &>/dev/null &) ;\
	fi
endif

### Detects a browser if not yet defined.
ifeq (,$(BROWSER))
BROWSERS = chromium firefox google-chrome brave opera
export BROWSER = $(shell l=($(foreach b,$(BROWSERS),$(shell if which -s $(b) ; then echo $(b) ; fi))) ; echo $${l[0]})
endif

show: # show[=$port] ; Shows a local http:127.0.0.1:$port page, port=8080 by default.
	$(MAKE) start=$(show)
	if [ \! -z "$(show)" ] ; then port=8080 ; else port="$(show)" ; fi ;\
	$(BROWSER) http://127.0.0.1:$$port

start: # stop[=$port] ; Stops, if not yet done, a local http:127.0.0.1:$port server, port=8080 by default..
	if [ \! -z "$(stop)" ] ; then port=8080 ; else port="$(stop)" ; fi ;\
	killall http://127.0.0.1:$$port

## Defines the API documentation and markdown file'es rendering generation

BUILD_API = beautify node_modules/jsdoc2 $(subst %.md,docs/%.html,$(wildcard *.md)) $(subst src/%.md,docs/%.html,$(wildcard *.md)) docs/index.html 

beautify:
ifneq (,$(shell which js-beautify))
	for f in $(wildcard */*.js) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; js-beautify -q -s 2 -n -r $$f ; touch $$f -r $$f~ ; done
endif
ifneq (,$(shell which css-beautify))
	for f in $(wildcard */*.css) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; css-beautify -q -s 2 -n -r $$f ; touch $$f -r $$f~ ; done
endif
ifneq (,$(shell which uncrustify))
	for f in $(wildcard *.hpp) $(wildcard *.cpp) $(wildcard *.C) ; do cp -p $$f $$f~ ; touch $$f~ -r $$f ; uncrustify -q -c node_modules/adnai-make/src/uncrustify.cfg -f $$f~ -o $$f ; touch $$f -r $$f~ ; done ; fi
endif

node_modules/docdash2:
	mkdir -p $@
	cp -rf {node_modules/docdash/{static,tmpl},node_modules/idnai/src/docdash2/publish.js} $@
	cp  ./docdash2/docdash2.js node_modules/jsdoc/plugins

docs/index.html: $(wildcard introduction.md) $(wildcard *.hpp) $(wildcard *.js) $(wildcard *.sh)
	echo '/** */' > ./.empty.js
	jsdoc -c node_modules/adnai-make/src/docdash2/config.json -t node_modules/docdash2 -R README.md -d docs ./.empty.js $(sort $(wildcard *.js))
	rm ./.empty.js

### Renders the markdown files

docs/%.html: src/%.md
	node_modules/idnai-make/bin/subst "@frame\\s+([^\\s]+)" "<p><center><iframe style='width: 100%; height: calc(66vh);' src='$1'></iframe></center><a href='$$1' target='_blank'>&nbsp;&nbsp;(open in new tab)</a></p>" $^ | node_modules/idnai-make/bin/md2html > $@

docs/%.html: %.md
	node_modules/idnai-make/bin/subst "@frame\\s+([^\\s]+)" "<p><center><iframe style='width: 100%; height: calc(66vh);' src='$1'></iframe></center><a href='$$1' target='_blank'>&nbsp;&nbsp;(open in new tab)</a></p>" $^ | node_modules/idnai-make/bin/md2html > $@

## Defines latex and related files compilation.

### Notes:
### - Input latex files are in the tex/ directory, with a \documentclass header.
### - Output latex files are in the docs/ directory.
### - Batch [maple](https://www.maplesoft.com) files are processed.
### - Drawings built with [libreoffice](https://fr.libreoffice.org) files are processed.
### - Each latex file first page is extracted as a thumbnail.

LATEX_MAINS = $(foreach f,$(wildcard */*.tex),$(if $(shell head -1 $(f) | grep '\\documentclass'),$(f),))
BUILD_LATEX = $(patsubst %.odg,%.png,$(wildcard %/*.odg)) $(patsubst %.mpl,%.mpl.out.txt,$(wildcard %/*.mpl)) $(patsubst tex/%.tex,docs/%.pdf,$(patsubst src/%.tex,tex/%.tex,$(LATEX_MAINS))) $(patsubst tex/%.tex,docs/%.png,$(patsubst src/%.tex,tex/%.tex,$(LATEX_MAINS)))

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

### Applies maple on maple souce file keeping trace locally of the output.
ifneq (,$(shell which maple))
%.mpl.out.txt: %.mpl
	cd $(@D) ; maple ../$^ > ../$@
	git add $@
endif

### Compiles libreoffice drawings.
ifneq (,$(shell which libreoffice))
%.png : %.odg
	libreoffice --headless --convert-to png --outdir $(@D) $^
	git add $@
endif

### Extracts the 1st page of each pdf to be used as thumbnail.
ifneq (,$(shell which pftk))
ifneq (,$(shell which convert))
docs/%.png: docs/%.pdf
	pdftk $^ cat 1 output /tmp/%-thumbnail.pdf ; convert /tmp/%-thumbnail.pdf $@ ; rm /tmp/%-thumbnail.pdf
	git add $@
endif
endif

## Defines C++ compilation rules

CCP = $if($(which clang),clang,$if($(which g++),g++,$if($(which c++),c++,)))

ifneq (,$(CPP))

OS=$(shell uname -s) 

CPP_FLAGS = -g -fPIC -Wall -std=c++17 -O3 -D OS=$(OS) \
 $(patsubst %,-I%,$(wildcard node_modules/*/src) $(wildcard /usr/include/python3.*) /usr/local/Frameworks/Python.framework/Headers)

ifeq (--debug,$(findstring --debug,$(MAKEFLAGS)))
CPP_FLAGS += -D VERBOSE
endif

BUILD_CPP = $(patsubst %.mpl,%.mpl.out.txt,$(wildcard node_modules/*/src/*.mpl)) $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp)) node_modules/libcpp.a $(patsubst %.C,%,$(wildcard node_modules/*/src/*.C)) 

%.o: %.cpp
	$(CPP) -c $(CPP_FLAGS) $^

node_modules/libcpp.so : $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp))
	$(CPP) -o $@ -fPIC -shared $^

CPP_LIBS = node_modules/libcpp.so -lstdc++ -lm $(shell find /usr/lib -name 'libpython3.*.so' | head -1)
ifneq (mingw64,$(OS))
CPP_LIBS  += -lcurl
endif

%.bin: %.C
	$(CPP) -o $@ $(CPP_FLAGS) $^ $(CPP_LIBS)
	cd $(dir $(dir $@))/bin ; ln -s ../src/$@ $*

endif

## Tests mechanisms 

test: # test[=file] [argv="arg1 …"] ; Runs a given test file, if specified, or all src/test.* files.
	if [ -z "$(test)" ] ; then \
	  if [ -f "src/test.C" ] ; then $(MAKE) $(BUILD_CPP) ; $(MAKE) test=src/test.bin $(argv) ; fi ;\
	  if [ -f "src/test.sh" ] ; then chmod a+rx test.sh ; ./src/test.sh $(argv) ; fi ;\
	  if [ -f "src/test.js" ] ; then chmod a+rx test.js ; ./src/test.js $(argv) ; fi ;\
	  if [ -f "src/test.py" ] ; then python3 ./src/test.py $(argv) ; fi ;\
	  if [ -f "src/test.mpl" -a \! -z "`which maple 2>/dev/null`" ] ; then maple src/test.mpl ; fi ;\
	  if [ -f "src/test.html" ] ; then $(BROWSER) src/test.html ; fi ;\
        else $(MAKE) $(BUILD_CPP) ; $(test) $(argv) fi

ifneq (,$(which gdb))
gtest: $(BUILD_CPP) # gtest[=file] [argv="arg1 …"] ; Runs a given test CPP file with gdb.
	if [ -z "$(test)" ] ; then test="src/test.bin" ; else test="$(test)" ; fi \
	unset DEBUGINFOD_URLS ;	(echo "break exit" ; echo "run $(argv)" ; echo "echo --- backtrace ------------------------------------------------------------------------------\n" ; echo "backtrace" ; echo "echo --- backtrace full -------------------------------------------------------------------------\n" ; echo "backtrace full" ; echo "quit 0") > /tmp/a.cmd ;\
	gdb -n -q $$test -x /tmp/a.cmd --return-child-result 2>&1 ; ok=
endif

ifneq (,$(which valgrind))
vtest: $(BUILD_CPP) # vtest[=file] [argv="arg1 …"] ; Runs a given test CPP file with valgrind.
	if [ -z "$(test)" ] ; then test="src/test.bin" ; else test="$(test)" ; fi \
	ulimit -s 100000 2>/dev/null ; export GLIBCXX_FORCE_NEW=1 ; valgrind --max-stackframe=100000000 --track-origins=yes $$test $(argv)
endif

## Integrates derived packages makefile rurles if any 

ifneq (,$(shell find -wholename node_modules/idnai-esp32/src/makefile-rules.mk))
include node_modules/idnai-esp32/src/makefile-rules.mk
endif

## Package
## Builds or cleans all files defined by the previous rules.

BUILD = $(BUILD_INSTALL) $(BUILD_API) $(BUILD_API) $(BUILD_LATEX) $(BUILD_CPP) $(BUILD_ESP32)

build: # build=[hostname[/path]] ; Builds targets defined by the makefile rules, locally or on an accessible host, path=~/gits by default.
	if [ -z "$(build)" ] ;\
	then $(MAKE) $(BUILD) ;\
	else \
	  $(MAKE) sync ;\
	  if [ "$(notdir ($build))" = "$(build)" ] ;\
	  then d="~/gits" ;\
	  else d="$(notdir ($build))" ;\
	  fi ;\
	  ssh "`echo '$(build)' | sed 's/\/.*//g'`" -c "cd $$d/$(NAME) ; make sync build sync" ;\
	fi

clean: # clean ; Removes all targets defined by the makefile rules.
	node_modules/idnai-make/bin/clean
	/bin/rm -rf $(BUILD)

rebuild: clean build  # rebuild ; Cleans and builds all targets defined by the makefile rules.

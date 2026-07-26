# These are the idnai makefile rules
## Note:
## - Partial installation policy: If a software is missing, the rule is ignored, assuming it is processed from another checkout.

## Configures the makefile with bash, in silent mode, avoiding spurious parallelism, and extending path.

export SHELL := /bin/bash

MAKEFILES = makefile node_modules/idnai-make/src/makefile-rules.mk

.SILENT: $(shell cat $(MAKEFILES) | sed -n 's/^\([^:]*\):.*/\1/p')

.NOTPARALLEL:

export PATH := $(PWD)/bin $(PWD)/node_modules/.bin $(wildcard $(PWD)/node_modules/*/bin) $(PATH)

## Detects rules with parameters if any, else shows usage.

default:
	tbd=true ; for target in sync install start show stop test ;\
	  if [ \! -z "$($(target))" ; then tbd=false ; $(MAKE) $(target) ;\
	fi ; done ; if tbd ; then $(MAKE) usage ; fi

## Shows the makefile usage, extracting all names targets with a line of documentation.

usage: # usage ; Shows the makefile usage.
	echo -e 'Usage: make $$command\n Commands:'
	cat $(MAKEFILES) | sed -n 's/^[a-z]*: *[^#]*# *\(.*\)/- \2/p'
### Note:
### - It is based on target's construct of the form 'target: dependencies # description'.

## Force synchronization with respect to git repositories

GITS=$(dir $(shell find -name '.git'))

sync: # sync[=$message] ; Synchronizes files with respect to the github repositories.
	if [ \! -z "$(sync)" ] ; then message="sync from makefile" ; else message="$(sync)" ; fi ;\
	find .. \( -name '*~' -o -name '*.o' -o -name '*.aux' -o -name '*.bbl' -o -name '*.blg' -o -name '*.out' -o -name '*.log' -o -name '*.toc' -o -name '*.nav' -o -name '*.snm'-o -name 'nohup.out' \) -delete
	for f in $(GITS) ; do pushd $$f > /dev/null ;\
	  git pull -q ; git commit -q -a -m "$(message)" ; git push -q ; git status -s ;\
	popd > /dev/null ; done

### Notes:
### - It detects git repository in the file tree with the .git directory
### - It cleans temporary files before synchronization.
### - It cheats w.r.t. commit message because useless in this context.

## Updates all required packages

update: # update ; Updates the repository installation.
	node_modules/idnai-make/bin/update

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

## Defines the .docs API documentation generation

BUILD_API = beautify node_modules/jsdoc2 docs/index.html

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

## Defines latex and related files compilation.

### Notes:
### - Input latex files are in the tex/ directory, with a \documentclass header.
### - Output latex files are in the docs/ directory.
### - Batch [maple](https://www.maplesoft.com) files are processed.
### - Drawings built with [libreoffice](https://fr.libreoffice.org) files are processed.
### - Each latex file first page is extracted as a thumbnail.

LATEX_MAINS = $(shell for f in tex/*.tex ; do if [ \! -z "`head -1 $$f | grep '\\documentclass'`" ] ; then echo $$f ; fi ; done)
BUILD_LATEX = $(patsubst tex/%.tex,docs/%.pdf,$(LATEX_MAINS)) $(patsubst tex/%.tex,docs/%.png,$(LATEX_MAINS))

### Applies pdflatex with the proper options and cleans all temporary unused files.
ifneq (,$(shell which pdflatex))
docs/%.pdf: tex/%.tex $(patsubst %.odg,%.png,$(wildcard tex/*.odg)) $(patsubst %.mpl,%.mpl.out.txt,$(wildcard tex/*.mpl)) $(wildcard tex/*.bib) $(filter-out $(LATEX_MAINS),$(wildcard tex/*.tex))
	cd tex; pdflatex -halt-on-error -draftmode $* ; bibtex $* ; pdflatex -halt-on-error -draftmode $* ; pdflatex -halt-on-error $* ; grep -i undefined $*.log ; rm -f $*.aux $*.bbl $*.blg $*.toc $*.nav $*.snm $*.out ; ok=
	mv tex/$*.pdf $@ 
	git add $@
endif

### Applies maple on maple souce file keeping trace locally of the output.
ifneq (,$(shell which maple))
%.mpl.out.txt: %.mpl
	cd tex ; maple ../$^ > ../$@
	git add $@
endif

### Compiles libreoffice drawings.
ifneq (,$(shell which libreoffice))
tex/%.png : tex/%.odg
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

ifneq (,$(which clang))
CPP = clang
else
ifneq (,$(which g++))
CPP = g++
else
ifneq (,$(which c++))
CPP = c++
endif
endif
endif

ifneq (,$(CPP))

OS=$(shell uname -s) 

CPP_FLAGS = -g -fPIC -Wall -std=c++17 -D OS=$(OS) \
 $(patsubst %,-I%,$(wildcard node_modules/*/src) $(wildcard /usr/include/python3.*) /usr/local/Frameworks/Python.framework/Headers)

ifeq (--debug,$(findstring --debug,$(MAKEFLAGS)))
CPP_FLAGS += -D VERBOSE
endif

BUILD_CPP = $(patsubst %.mpl,%.mpl.out.txt,$(wildcard node_modules/*/src/*.mpl)) $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp)) node_modules/libcpp.a $(patsubst %.C,%,$(wildcard node_modules/*/src/*.C)) 

%.o: %.cpp
	$(CPP) -c $(CPP_FLAGS) $^

node_modules/libcpp.so : $(patsubst %.cpp,%.o,$(wildcard node_modules/*/src/*.cpp))
	$(CPP) -o $@ -fPIC -shared $^

ar -rc $@ $^ ; ar -s $@

CPP_LIBS = node_modules/libcpp.so -lstdc++ -lm $(shell find /usr/lib -name 'libpython3.*.so' | head -1)
ifndef (mingw64,$(OS))
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

## Builds or cleans all files defined by the previous rules.

BUILD = $(BUILD_API) $(BUILD_LATEX) $(BUILD_CPP)

build: # build ; Builds all targets defined by the makefile rules.
	$(MAKE) $(BUILD)

clean: # clean ; Removes all targets defined by the makefile rules.
	/bin/rm -rf $(BUILD)

rebuild: clean build  # build ; Cleans and builds all targets defined by the makefile rules.

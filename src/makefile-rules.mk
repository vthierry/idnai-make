# These are the idnai makefile rules
## Note:
## - Partial installation policy: If a software is missing, the rule is ignored, assuming it is processed from another checkout.

## Configures the makefile in silent mode, with bash, avoiding spurious parallelism.

MAKEFILES = makefile ./etc/node_modules/idnai-make/src/makefile-rules.mk

.SILENT: $(shell cat $(MAKEFILES) | sed -n 's/^\([^:]*\):.*/\1/p')

export SHELL := /bin/bash

.NOTPARALLEL:

## Defines package variables

ROOT = $(dir $(PWD))
NAME = $(notdir $(ROOT))

## Shows the makefile usage, extracting all names targets with a line of documentation.

usage: # Shows the makefile usage.
	echo -e 'Usage: make $$command\n Commands:'
	cat $(MAKEFILES) | sed -n 's/^\([a-z]*\): *[^#]*# *\(.*\)/  \1: \2/p'
### Note:
### - It is based on target's construct of the form 'target: dependencies # description'.

### Generates a gison file 
docs/usage.gison: $(MAKEFILES)
	(echo '{' ;\
	 cat $(MAKEFILES) | sed -n 's/^\([a-z]*\): *[^#]*# *\(.*\)/  \1: "\2"/p' ;\
	 echo '}') > $@

## Force synchronization with respect to git repositories

GITS=$(dir $(shell find -name '.git'))

sync: # Synchronizes files with respect to the github repositories.
	find .. \( -name '*~' -o -name '*.o' -o -name '*.aux' -o -name '*.bbl' -o -name '*.blg' -o -name '*.out' -o -name '*.log' -o -name '*.toc' -o -name '*.nav' -o -name '*.snm'-o -name 'nohup.out' \) -delete
	for f in $(GITS) ; do pushd $$f > /dev/null ;\
	  git pull -q ; git commit -q -a -m 'sync from makefile' ; git push -q ; git status -s ;\
	popd > /dev/null ; done
### Notes:
### - It cleans temporary files before synchronization.
### - It cheats w.r.t. commit message because useless in this context.

## Defines latex and related files compilation.
### Notes:
### - Input latex files are in the tex/ directory, with a \documentclass header.
### - Output latex files are in the docs/ directory.
### - Batch [maple](https://www.maplesoft.com) files are processed.
### - Drawings built with [libreoffice](https://fr.libreoffice.org) files are processed.
### - Each latex file first page is extracted as a thumbnail.

BUILD_LATEX = $(patsubst tex/%.tex,docs/%.pdf,$(shell for f in tex/*.tex ; do if [ \! -z "`head -1 $$f | grep '\\documentclass'`" ] ; then echo $$f ; fi ; done))

### Applies pdflatex with the proper options and cleans all temporary unused files.
ifneq (,$(shell which pdflatex))
docs/%.pdf: tex/%.tex $(wildcard tex/*.odg) $(wildcard tex/*.mpl) $(wildcard tex/*.bib)
	cd tex; pdflatex -halt-on-error -draftmode $* ; bibtex $* ; pdflatex -halt-on-error -draftmode $* ; pdflatex -halt-on-error $* ; grep -i undefined $*.log ; rm -f $*.aux $*.bbl $*.blg $*.toc $*.nav $*.snm $*.out ; ok=
	mv tex/$*.pdf $@ 
	git add $@
endif

### Applies maple on maple souce file keeping trace locally of the output.
ifneq (,$(shell which maple))
tex/%.mpl.out.txt: tex/%.mpl
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


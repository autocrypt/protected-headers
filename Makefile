#!/usr/bin/make -f

draft = draft-protected-headers
OUTPUT = $(draft).txt $(draft).html $(draft).xml $(draft).pdf
vectors = $(shell ./generate-test-vectors list-vectors)
vectordata = $(foreach x,$(vectors), $(x).eml)
innerdata = $(foreach x, $(shell ./generate-test-vectors list-vectors | grep -vx signed), $(x).inner)

all: $(OUTPUT)

%.xmlv2: %.md
	kramdown-rfc2629 < $< > $@.tmp
	mv $@.tmp $@

%.xml: %.xmlv2
	xml2rfc --v2v3 -o $@ $<

%.html: %.xml
	xml2rfc $< --html

%.pdf: %.xml
	xml2rfc $< --pdf

%.txt: %.xml
	xml2rfc $< --text

$(draft).md: $(draft).in.md assemble $(vectordata) $(innerdata)
	./assemble < $< >$@.tmp
	mv $@.tmp $@

%.eml: generate-test-vectors
	./generate-test-vectors $* >$@.tmp
	mv $@.tmp $@

%.inner: %.eml
	./extract-inner < $< > $@.tmp
	mv $@.tmp $@

clean:
	-rm -rf $(OUTPUT) metadata.min.js *.tmp

check: draft-protected-headers.txt
	echo "checking for overlong lines..."
	! egrep '.{73,}' < draft-protected-headers.txt
	./test-notmuch

.PHONY: clean all check
.SECONDARY: $(vectordata) draft-protected-headers.md $(innerdata)

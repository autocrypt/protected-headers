#!/usr/bin/make -f

draft = draft-protected-headers
OUTPUT = $(draft).txt $(draft).html $(draft).xml
vectors = $(shell ./generate-test-vectors list-vectors)
vectordata = $(foreach x,$(vectors), $(x).eml)
innerdata = $(foreach x, $(shell ./generate-test-vectors list-vectors | grep -vx signed), $(x).inner)

all: $(OUTPUT)

%.xml: %.md
	kramdown-rfc2629 < $< > $@.tmp
	mv $@.tmp $@

%.html: %.xml
	xml2rfc $< --html --v3

%.txt: %.xml
	xml2rfc $< --text --v3

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

.PHONY: clean all
.SECONDARY: $(vectordata) draft-protected-headers.md $(innerdata)
